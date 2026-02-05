class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable

  has_one :merchant, dependent: :destroy
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  has_many :audit_logs, dependent: :destroy

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 8 }, if: :password_required?
  validates :password, format: {
    with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+\z/,
    message: "must include at least one uppercase letter, one lowercase letter, one number, and one special character"
  }, if: :password_required?

  def has_role?(role_name)
    roles.exists?(name: role_name)
  end

  def add_role(role_name)
    role = Role.find_or_create_by(name: role_name)
    roles << role unless has_role?(role_name)
  end

  def remove_role(role_name)
    role = Role.find_by(name: role_name)
    user_roles.where(role: role).destroy_all if role
  end

  private

  def password_required?
    !persisted? || (!password.nil? && !password_confirmation.nil?)
  end
end
