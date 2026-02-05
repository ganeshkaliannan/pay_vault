class TransactionsController < ApplicationController
  before_action :authenticate_user!

  def index
    if current_user.has_role?("admin")
      # Admin sees all transactions
      @transactions = Transaction.includes(:merchant, :payment, :payout)
                                 .order(created_at: :desc)
                                 .page(params[:page])
                                 .per(2)
    else
      # Merchant sees only their own transactions
      merchant = current_user.merchant

      if merchant
        @transactions = merchant.transactions
                               .includes(:payment, :payout)
                               .order(created_at: :desc)
                               .page(params[:page])
                               .per(2)
      else
        @transactions = Transaction.none.page(1)
      end
    end
  end
end
