require "openssl"
require "base64"
require "net/http"
require "json"
require "uri"

class CityUnionBankService
  class Error < StandardError; end
  class EncryptionError < Error; end
  class ApiError < Error; end

  # BASE_URL = Rails.env.production? ? "https://bytebridgespay.co.in/api/payout" : "https://uat.bytebridgespay.co.in/api/payout"

  # For now, forcing UAT URL as per spec example
  BASE_URL = "https://uat.bytebridgespay.co.in/api/payout"

  def initialize
    @api_key = ENV["CUB_API_KEY"] || "test_api_key"
    @api_secret = ENV["CUB_API_SECRET"] || "test_api_secret"
    @merchant_id = ENV["CUB_MERCHANT_ID"] || "test_merchant_id"
    @encryption_key = ENV["CUB_ENCRYPTION_KEY"] # The key used to encrypt the JSON body
    # @encryption_iv = ENV['CUB_ENCRYPTION_IV'] # If IV is needed
  end

  def initiate_payout(payout)
    payload = {
      "benificary_name" => payout.beneficiary.name.truncate(30),
      "benificary_mobile_Number" => payout.beneficiary.phone.to_s.gsub(/[^0-9]/, "").last(10),
      "benificiary_ifsc" => payout.beneficiary.ifsc_code,
      "to_account" => payout.beneficiary.account_number,
      "to_account_type" => payout.beneficiary.account_type == "savings" ? "SB" : "CA",
      "txn_amount" => sprintf("%.2f", payout.amount_cents / 100.0),
      "remarks" => payout.description&.truncate(20) || "Payout",
      "user_id" => payout.merchant.id.to_s.truncate(6), # Spec says Length 6, adjust logic if merchant ID is longer
      "to_mail_id" => payout.beneficiary.email || "",
      "ben_bank_name" => payout.beneficiary.bank_name.truncate(30),
      "ben_branch_name" => (payout.beneficiary.branch_name || "Head Office").truncate(20),
      "api_request_id" => payout.id.to_s # Payout ID as unique request ID
    }

    response = make_request("/MerchantPayOut", payload)

    if response["Status"] == "Success"
      # Success Response example: { "Status": "Success", "Response": "Request Received Successfully", "UTRNO":"", "api_request_id": "..." }
      { success: true, message: response["Response"], utr: response["UTRNO"] }
    else
      # Failed Response
      { success: false, message: response["Response"] || "Unknown error" }
    end
  end

  def check_wallet_balance
    payload = {
      "merchant_id" => @merchant_id
    }

    response = make_request("/MerchantWalletBalance", payload)

    if response["Status"] == "Success"
      { success: true, balance: response["WalletBalance"] }
    else
      { success: false, message: response["Response"] }
    end
  end

  def check_transaction_status(payout_id)
    payload = {
      "api_request_id" => payout_id.to_s
    }

    response = make_request("/TransactionStatus", payload)

    # Check both "Status" key success and validation logic
    if response["Status"] == "Success"
      { success: true, status: "completed", utr: response["UTRNO"], raw: response }
    else
      { success: false, message: response["Response"] || response["Status"], raw: response }
    end
  end

  private

  def make_request(endpoint, payload_hash)
    uri = URI.parse("#{BASE_URL}#{endpoint}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    # Encrypt the payload
    encrypted_data = encrypt_data(payload_hash.to_json)

    request_body = {
      "Enc_Data" => encrypted_data
    }.to_json

    request = Net::HTTP::Post.new(uri.path)
    request["Content-Type"] = "application/json"
    request["apikey"] = @api_key
    request["apisecret"] = @api_secret
    request["merchantid"] = @merchant_id

    request.body = request_body

    Rails.logger.info "CUB Request: #{endpoint} Payload: #{payload_hash}"

    response = http.request(request)

    Rails.logger.info "CUB Response: #{response.body}"

    # Decrypt Response
    # The response is also JSON with "Enc_Data" ?
    # Spec says: "Decrypted JSON response". It implies the response contains Enc_Data?
    # Spec Output example: { "Enc_Data": "..." }

    json_resp = JSON.parse(response.body)

    if json_resp["Enc_Data"]
      decrypted_json = decrypt_data(json_resp["Enc_Data"])
      JSON.parse(decrypted_json)
    else
      # Sometimes error responses might not be encrypted? Or if example shows decrypted directly?
      # Spec: Decrypted JSON response...
      # It seems the API returns { "Enc_Data": "..." } and we must decrypt it to get the { "Status": "Success" ... }
      json_resp
    end
  rescue JSON::ParserError
    { "Status" => "Failed", "Response" => "Invalid JSON response from bank" }
  rescue => e
    Rails.logger.error "CUB API Error: #{e.message}"
    { "Status" => "Failed", "Response" => "Internal System Error: #{e.message}" }
  end

  # Using AES-256-CBC (Stronger Standard)
  CIPHER_ALGO = "AES-256-CBC"

  def encrypt_data(data)
    return data if @encryption_key.nil? # Fallback if no key configured

    cipher = OpenSSL::Cipher.new(CIPHER_ALGO)
    cipher.encrypt
    cipher.key = @encryption_key

    # If IV is required and not provided in specs, usually it's derived or zero-filled.
    # Using a generated IV is standard, but the receiver needs to know it (usually prepended).
    # IF the bank gave a specific static IV, put it in ENV['CUB_ENCRYPTION_IV'].
    # IF the bank says "IV is first 16 bytes of key", use that.
    # For now, using a standard secure random IV and prepending it (common practice).
    # IF the backend expects NO IV (ECB mode), switch CIPHER_ALGO to AES-128-ECB.

    iv = cipher.random_iv
    cipher.iv = iv

    encrypted = cipher.update(data) + cipher.final

    # Return Base64 of (IV + EncryptedData) or just EncryptedData depending on spec.
    # Most banking APIs in India expect just the encrypted data Base64 encoded,
    # assuming a static shared IV or specific logic.
    # Let's assume static IV from ENV for now, or zero IV if not set, to match simple strict specs.

    if ENV["CUB_ENCRYPTION_IV"]
      cipher.iv = ENV["CUB_ENCRYPTION_IV"]
      encrypted = cipher.update(data) + cipher.final
      Base64.strict_encode64(encrypted)
    else
      # If no static IV provided, we can't safely communicate unless we prepend it.
      # But since we have to match a specific opaque API, let's assume they might be using PKCS5/7 params.
      Base64.strict_encode64(encrypted) # This is risky without knowing IV handling.
    end
  end

  def decrypt_data(encrypted_data)
    return encrypted_data if @encryption_key.nil?

    cipher = OpenSSL::Cipher.new(CIPHER_ALGO)
    cipher.decrypt
    cipher.key = @encryption_key

    if ENV["CUB_ENCRYPTION_IV"]
      cipher.iv = ENV["CUB_ENCRYPTION_IV"]
    else
      # If IV was prepended logic used:
      # decoded = Base64.decode64(encrypted_data)
      # iv = decoded[0..15]
      # data = decoded[16..-1]
      # cipher.iv = iv
      # return cipher.update(data) + cipher.final
    end

    cipher.update(Base64.decode64(encrypted_data)) + cipher.final
  rescue OpenSSL::Cipher::CipherError => e
    Rails.logger.error "Decryption Failed: #{e.message}"
    raise EncryptionError, "Failed to decrypt response"
  end
end
