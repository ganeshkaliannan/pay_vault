class SettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_merchant_settings

  def index
  end

  def security
  end

  def payout
    # Payout-specific settings (schedule, minimum amount, etc.)
  end

  def notifications
  end

  def bank_accounts
    # Manage merchant bank accounts
    if current_user.has_role?("admin")
      @bank_accounts = BankAccount.all
    else
      @bank_accounts = current_merchant.bank_accounts
    end
  end

  private

  def current_merchant
    @current_merchant ||= current_user.merchant if current_user && !current_user.has_role?("admin")
  end
  helper_method :current_merchant

  def load_merchant_settings
    if current_user.has_role?("admin")
      # Admin sees system-wide settings
      @settings = {
        role: "admin",
        total_merchants: Merchant.count,
        total_payments: Payment.sum(:amount_cents),
        total_payouts: Payout.sum(:amount_cents),
        system_balance: Merchant.sum(:balance_cents)
      }
    else
      # Merchant sees their own settings
      merchant = current_merchant

      if merchant
        @settings = {
          role: "merchant",
          business_name: merchant.company_name,
          email: merchant.email,
          phone: merchant.phone,
          status: merchant.status,
          balance_cents: merchant.balance_cents,
          currency: merchant.currency,

          # Payout settings from merchant.settings JSONB
          payout_settings: merchant.settings || {},

          # Notification settings
          notification_settings: {
            email: merchant.email,
            payment_notifications: true,
            payout_notifications: true,
            low_balance_alert: true,
            low_balance_threshold: 10000 # $100
          },

          # Security settings
          security_settings: {
            two_factor_auth: false, # TODO: Implement 2FA
            last_login: current_user.current_sign_in_at,
            sign_in_count: current_user.sign_in_count,
            last_sign_in_ip: current_user.last_sign_in_ip,
            ip_whitelist_enabled: false
          },

          # Bank accounts
          bank_accounts_count: merchant.bank_accounts.count,
          primary_bank_account: merchant.bank_accounts.find_by(is_primary: true)
        }
      else
        # User doesn't have a merchant account yet
        @settings = {
          role: "user",
          message: "No merchant account found. Please contact admin."
        }
      end
    end
  end
end
