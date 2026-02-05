class Transaction < ApplicationRecord
  belongs_to :merchant
  belongs_to :payment, optional: true
  belongs_to :payout, optional: true

  # Validations
  validates :amount_cents, presence: true
  validates :currency, presence: true
  validates :transaction_type, presence: true, inclusion: { in: %w[credit debit] }
  validates :status, presence: true, inclusion: { in: %w[pending completed failed reversed] }
  validates :balance_before_cents, presence: true
  validates :balance_after_cents, presence: true
  validate :must_have_payment_or_payout

  # Enums
  enum :transaction_type, {
    credit: "credit",
    debit: "debit"
  }, prefix: true

  enum :status, {
    pending: "pending",
    completed: "completed",
    failed: "failed",
    reversed: "reversed"
  }, prefix: true

  # Scopes
  scope :for_merchant, ->(merchant_id) { where(merchant_id: merchant_id) }
  scope :credits, -> { where(transaction_type: "credit") }
  scope :debits, -> { where(transaction_type: "debit") }
  scope :completed, -> { where(status: "completed") }
  scope :recent, -> { order(created_at: :desc) }

  # Instance methods
  def amount
    Money.new(amount_cents, currency)
  end

  def balance_before
    Money.new(balance_before_cents, currency)
  end

  def balance_after
    Money.new(balance_after_cents, currency)
  end

  def source
    payment || payout
  end

  private

  def must_have_payment_or_payout
    if payment.blank? && payout.blank?
      errors.add(:base, "Transaction must be associated with either a payment or a payout")
    end

    if payment.present? && payout.present?
      errors.add(:base, "Transaction cannot be associated with both payment and payout")
    end
  end
end
