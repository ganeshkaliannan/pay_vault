class Beneficiary < ApplicationRecord
  belongs_to :merchant
  has_many :payouts, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true
  validates :account_number, presence: true
  validates :ifsc_code, presence: true, format: { with: /\A[A-Z]{4}0[A-Z0-9]{6}\z/, message: "must be valid IFSC code" }
  validates :bank_name, presence: true
  validates :account_type, presence: true, inclusion: { in: %w[savings current] }
  validates :status, presence: true, inclusion: { in: %w[active inactive] }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone, format: { with: /\A[+]?[0-9]{10,15}\z/ }, allow_blank: true

  # Scopes
  scope :active, -> { where(status: "active") }
  scope :verified, -> { where(is_verified: true) }
  scope :for_merchant, ->(merchant_id) { where(merchant_id: merchant_id) }

  # Instance methods
  def display_account
    "#{bank_name} - ****#{account_number.last(4)}"
  end

  def verify!
    update(is_verified: true)
  end

  def deactivate!
    update(status: "inactive")
  end
end
