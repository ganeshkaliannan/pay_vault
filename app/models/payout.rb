class Payout < ApplicationRecord
  belongs_to :bank_account, optional: true
  belongs_to :merchant
  belongs_to :beneficiary, optional: true

  # Associations
  has_many :transactions, dependent: :destroy

  # Validations
  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending scheduled processing completed failed cancelled] }
  validates :payout_method, inclusion: { in: %w[bank_transfer imps neft rtgs] }, allow_nil: true
  validates :fee_cents, numericality: { greater_than_or_equal_to: 0 }
  validate :merchant_has_sufficient_balance, on: :create
  validate :merchant_must_be_active, on: :create

  # Enums
  enum :status, {
    pending: "pending",
    scheduled: "scheduled",
    processing: "processing",
    completed: "completed",
    failed: "failed",
    cancelled: "cancelled"
  }, prefix: true

  # Scopes
  scope :for_merchant, ->(merchant_id) { where(merchant_id: merchant_id) }
  scope :pending, -> { where(status: "pending") }
  scope :scheduled, -> { where(status: "scheduled") }
  scope :completed, -> { where(status: "completed") }
  scope :due_for_processing, -> { where(status: "scheduled").where("scheduled_at <= ?", Time.current) }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  after_create :deduct_from_merchant_balance
  after_update :create_transaction_on_completion, if: :saved_change_to_status?

  # Instance methods
  def amount
    Money.new(amount_cents, currency)
  end

  def fee
    Money.new(fee_cents, currency)
  end

  def total_amount
    Money.new(amount_cents + fee_cents, currency)
  end

  def process_with_city_union_bank!
    # This will be implemented with actual City Union Bank API integration
    update!(status: "processing", processed_at: Time.current)

    # TODO: Call City Union Bank API here
    # CityUnionBankService.new(self).process_payout

    # For now, mark as completed (will be updated when API is integrated)
    mark_as_completed!
  end

  def mark_as_completed!
    update!(status: "completed", completed_at: Time.current)
  end

  def mark_as_failed!(reason)
    update!(
      status: "failed",
      failure_reason: reason,
      metadata: metadata.merge(failed_at: Time.current)
    )

    # Refund the amount back to merchant balance
    merchant.add_to_balance(amount_cents + fee_cents)
  end

  def cancel!
    return unless status.in?(%w[pending scheduled])

    update!(status: "cancelled")
    # Refund the amount back to merchant balance
    merchant.add_to_balance(amount_cents + fee_cents)
  end

  private

  def merchant_has_sufficient_balance
    total = amount_cents + fee_cents
    if merchant.balance_cents < total
      errors.add(:base, "Insufficient balance. Required: #{total}, Available: #{merchant.balance_cents}")
    end
  end

  def deduct_from_merchant_balance
    merchant.deduct_from_balance(amount_cents + fee_cents)
  end

  def create_transaction_on_completion
    return unless status == "completed" && transactions.where(transaction_type: "debit").none?

    balance_before = merchant.balance_cents + amount_cents + fee_cents

    description_text = if beneficiary
      "Payout to #{beneficiary.name} (#{beneficiary.bank_name})"
    elsif bank_account
      "Payout to #{bank_account.account_holder_name}"
    else
      "Payout request"
    end

    Transaction.create!(
      merchant: merchant,
      payout: self,
      amount_cents: -(amount_cents + fee_cents),
      currency: currency,
      transaction_type: "debit",
      status: "completed",
      description: description_text,
      balance_before_cents: balance_before,
      balance_after_cents: merchant.balance_cents
    )
  end

  def merchant_must_be_active
    if merchant.present? && merchant.status != "active"
      errors.add(:merchant, "must be active to request payouts")
    end
  end
end
