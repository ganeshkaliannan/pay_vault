class BankAccount < ApplicationRecord
  belongs_to :accountable, polymorphic: true

  # Associations
  has_many :payouts, dependent: :restrict_with_error

  # Validations
  validates :account_holder_name, presence: true
  validates :account_number, presence: true
  validates :bank_name, presence: true
  validates :currency, presence: true
  validates :account_type, inclusion: { in: %w[savings current] }, allow_nil: true

  # Scopes
  scope :verified, -> { where(is_verified: true) }
  scope :primary, -> { where(is_primary: true) }
  scope :for_accountable, ->(accountable) { where(accountable: accountable) }

  # Callbacks
  before_save :ensure_only_one_primary, if: :is_primary?

  # Instance methods
  def masked_account_number
    return nil if account_number.blank?
    "****#{account_number.last(4)}"
  end

  def verify!
    update!(is_verified: true)
  end

  def set_as_primary!
    transaction do
      accountable.bank_accounts.update_all(is_primary: false)
      update!(is_primary: true)
    end
  end

  def can_be_deleted?
    !is_primary? && payouts.none?
  end

  private

  def ensure_only_one_primary
    if is_primary? && is_primary_changed?
      accountable.bank_accounts.where.not(id: id).update_all(is_primary: false)
    end
  end
end
