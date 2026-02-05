class PayoutProcessingJob < ApplicationJob
  queue_as :default

  def perform(payout_id)
    payout = Payout.find_by(id: payout_id)
    return unless payout

    # Double check status is pending
    return unless payout.status == "pending"

    service = CityUnionBankService.new
    result = service.initiate_payout(payout)

    if result[:success]
      # Bank accepted the request
      payout.update!(
        status: "processing",
        processed_at: Time.current,
        metadata: (payout.metadata || {}).merge(
          bank_message: result[:message],
          initial_utr: result[:utr]
        )
      )
    else
      # Bank rejected the request immediately
      payout.mark_as_failed!(result[:message])
    end
  rescue => e
    # Unexpected error (network, bug)
    # We might want to retry, or fail. Sidekiq has retries by default.
    # If it's a permanent failure, we should handle it.
    Rails.logger.error "PayoutProcessingJob Error: #{e.message}"

    # For now, let it retry (raise error)
    raise e
  end
end
