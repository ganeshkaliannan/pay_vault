class Merchant < ApplicationRecord
  belongs_to :user

  # Associations
  has_many :payments, dependent: :destroy
  has_many :transactions, dependent: :destroy
  has_many :payouts, dependent: :destroy
  has_many :beneficiaries, dependent: :destroy
  has_many :bank_accounts, as: :accountable, dependent: :destroy
  has_many :audit_logs, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :company_name, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending active suspended inactive] }
  validates :balance_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true, inclusion: { in: %w[USD EUR GBP INR] }
  validates :business_type, inclusion: { in: %w[sole_proprietorship partnership llc corporation] }, allow_nil: true

  # Enums
  enum :status, {
    pending: "pending",
    active: "active",
    suspended: "suspended",
    inactive: "inactive"
  }, prefix: true

  # Scopes
  scope :active, -> { where(status: "active") }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_balance, -> { order(balance_cents: :desc) }

  # Callbacks
  before_create :set_default_settings

  # Instance methods
  def balance
    Money.new(balance_cents, currency)
  end

  def balance=(amount)
    self.balance_cents = amount.cents
  end

  def add_to_balance(amount_cents)
    increment!(:balance_cents, amount_cents)
  end

  def deduct_from_balance(amount_cents)
    decrement!(:balance_cents, amount_cents)
  end

  def primary_bank_account
    bank_accounts.find_by(is_primary: true)
  end

  def total_payments
    payments.sum(:amount_cents)
  end

  def total_payouts
    payouts.where(status: "completed").sum(:amount_cents)
  end

  def activate!
    update!(status: "active")
  end

  def suspend!
    update!(status: "suspended")
  end

  private

  def set_default_settings
    self.settings ||= {
      payout_schedule: "manual",
      minimum_payout_amount: 1000, # in cents
      auto_payout_enabled: false
    }
  end
end
