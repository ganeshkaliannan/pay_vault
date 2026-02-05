class AuditLog < ApplicationRecord
  belongs_to :user
  belongs_to :merchant, optional: true

  # Validations
  validates :action, presence: true

  # Scopes
  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :for_merchant, ->(merchant_id) { where(merchant_id: merchant_id) }
  scope :for_resource, ->(type, id) { where(resource_type: type, resource_id: id) }
  scope :by_action, ->(action) { where(action: action) }
  scope :recent, -> { order(created_at: :desc) }

  # Class methods
  def self.log_action(user:, action:, resource: nil, merchant: nil, ip_address: nil, user_agent: nil, metadata: {})
    create!(
      user: user,
      merchant: merchant,
      action: action,
      resource_type: resource&.class&.name,
      resource_id: resource&.id,
      ip_address: ip_address,
      user_agent: user_agent,
      metadata: metadata
    )
  end
end
