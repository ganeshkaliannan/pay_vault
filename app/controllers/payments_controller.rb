class PaymentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_payment, only: [ :show ]

  def index
    if current_user.has_role?("admin")
      # Admin sees all payments
      @payments = Payment.includes(:merchant)
                         .order(created_at: :desc)
                         .page(params[:page])
                         .per(2)
    else
      # Merchant sees only their own payments
      merchant = current_user.merchant

      if merchant
        @payments = merchant.payments
                           .order(created_at: :desc)
                           .page(params[:page])
                           .per(2)
      else
        @payments = Payment.none.page(1)
      end
    end
  end

  def show
  end

  private

  def set_payment
    if current_user.has_role?("admin")
      @payment = Payment.find(params[:id])
    else
      @payment = current_user.merchant.payments.find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to payments_path, alert: "Payment not found or access denied."
  end
end
