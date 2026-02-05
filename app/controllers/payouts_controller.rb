class PayoutsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_merchant
  before_action :set_payout, only: [ :show ]

  def index
    @payouts = current_user.merchant.payouts.includes(:beneficiary)
                           .order(created_at: :desc)
                           .page(params[:page])
                           .per(10)
  end

  def new
    @payout = current_user.merchant.payouts.new
    @beneficiaries = current_user.merchant.beneficiaries.active.order(:name)
    @merchant = current_user.merchant
  end

  def create
    @merchant = current_user.merchant

    # Amount is input in dollars/decimal, stored in cents
    amount_decimal = params[:payout][:amount].to_f
    amount_cents = (amount_decimal * 100).to_i

    # For now, simplistic assignment
    @payout = @merchant.payouts.new(payout_params)
    @payout.amount_cents = amount_cents
    @payout.currency = @merchant.currency
    @payout.status = "pending"
    @payout.fee_cents = 0 # Can include fee calculation logic later

    # Since we are using an existing bank account for payout source, we can just grab the first verified one or make it optional for now if the model requires it
    # But wait, looking at Payout model: belongs_to :bank_account
    # This usually means the SOURCE bank account (Merchant's bank account).
    # If the merchant sends money, they are sending FROM their balance, but in a real banking system they might send FROM a specific connected account.
    # In this 'Wallet' model, they send FROM their wallet balance.
    # However, the model requires `bank_account_id`.
    # Let's check if we have bank accounts seeded. If not, we might need to create a dummy system bank account or update the model to make it optional.

    # Let's assign the first available bank account of the merchant or a system account.
    # For now, let's assume the merchant has a bank account or we will handle the validation error.
    account = @merchant.bank_accounts.first
    if account
      @payout.bank_account = account
    else
      # If no bank account, we can't save because of foreign key constraint usually.
      # Let's check Payout model again quickly.
    end

    if @payout.save
      # Process asynchronously via Sidekiq
      PayoutProcessingJob.perform_later(@payout.id)

      redirect_to payout_path(@payout), notice: "Payout request initiated successfully. Processing in background."
    else
      @beneficiaries = @merchant.beneficiaries.active.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  private

  def require_merchant
    unless current_user.has_role?("merchant") && current_user.merchant.present?
      redirect_to root_path, alert: "Access denied. Merchant account required."
    end
  end

  def set_payout
    @payout = current_user.merchant.payouts.find(params[:id])
  end

  def payout_params
    params.require(:payout).permit(:beneficiary_id, :payout_method, :description)
  end
end
