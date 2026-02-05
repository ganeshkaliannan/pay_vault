class Payment < ApplicationRecord
  belongs_to :merchant

  # Associations
  has_many :transactions, dependent: :destroy

  # Validations
  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending processing completed failed refunded] }
  validates :payment_method, inclusion: { in: %w[card bank_transfer upi wallet] }, allow_nil: true
  validates :gateway_transaction_id, uniqueness: true, allow_nil: true
  validate :merchant_must_be_active, on: :create

  # Enums
  enum :status, {
    pending: "pending",
    processing: "processing",
    completed: "completed",
    failed: "failed",
    refunded: "refunded"
  }, prefix: true

  # Scopes
  scope :completed, -> { where(status: "completed") }
  scope :pending, -> { where(status: "pending") }
  scope :for_merchant, ->(merchant_id) { where(merchant_id: merchant_id) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_amount, -> { order(amount_cents: :desc) }

  # Callbacks
  after_update :create_transaction_on_completion, if: :saved_change_to_status?

  # Helper methods to access customer info from metadata
  def customer_name
    metadata&.dig("customer_name")
  end

  def customer_email
    metadata&.dig("customer_email")
  end

  # Instance methods
  def amount
    Money.new(amount_cents, currency)
  end

  def amount=(money)
    self.amount_cents = money.cents
    self.currency = money.currency.to_s
  end

  def mark_as_completed!
    update!(status: "completed", processed_at: Time.current)
  end

  def mark_as_failed!(reason = nil)
    update!(status: "failed", metadata: metadata.merge(failure_reason: reason))
  end

  private

  def create_transaction_on_completion
    return unless status == "completed" && transactions.where(transaction_type: "credit").none?

    balance_before = merchant.balance_cents
    merchant.add_to_balance(amount_cents)

    Transaction.create!(
      merchant: merchant,
      payment: self,
      amount_cents: amount_cents,
      currency: currency,
      transaction_type: "credit",
      status: "completed",
      description: description || "Payment received",
      balance_before_cents: balance_before,
      balance_after_cents: merchant.reload.balance_cents
    )
  end

  def merchant_must_be_active
    if merchant.present? && merchant.status != "active"
      errors.add(:merchant, "must be active to process payments")
    end
  end
end
