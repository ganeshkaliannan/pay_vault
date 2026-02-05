class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user
    @roles = @user.roles

    if @user.has_role?("admin")
      # Admin sees system-wide statistics
      @stats = {
        role: "admin",
        total_revenue: Payment.where(status: "completed").sum(:amount_cents),
        total_payments: Payment.count,
        total_merchants: Merchant.count,
        active_merchants: Merchant.where(status: "active").count,
        total_payouts: Payout.sum(:amount_cents),
        pending_payouts: Payout.where(status: "pending").count,
        system_balance: Merchant.sum(:balance_cents)
      }

      # Recent payments across all merchants
      @recent_payments = Payment.includes(:merchant).order(created_at: :desc).limit(10)

    else
      # Merchant sees their own statistics
      merchant = @user.merchant

      if merchant
        @stats = {
          role: "merchant",
          balance: merchant.balance_cents,
          total_revenue: merchant.payments.where(status: "completed").sum(:amount_cents),
          total_payments: merchant.payments.count,
          completed_payments: merchant.payments.where(status: "completed").count,
          pending_payments: merchant.payments.where(status: "pending").count,
          total_payouts: merchant.payouts.sum(:amount_cents),
          pending_payouts: merchant.payouts.where(status: "pending").count
        }

        # Recent payments for this merchant
        @recent_payments = merchant.payments.order(created_at: :desc).limit(10)
      else
        @stats = {
          role: "user",
          message: "No merchant account found"
        }
        @recent_payments = []
      end
    end
  end
end
