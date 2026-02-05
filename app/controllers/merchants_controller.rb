class MerchantsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :set_merchant, only: [ :show, :edit, :update, :destroy, :add_funds, :fund ]

  def index
    @merchants = Merchant.includes(:user)
                         .order(created_at: :desc)
                         .page(params[:page])
                         .per(25)
  end

  def show
  end

  def new
    @merchant = Merchant.new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]

    if @user.save
      @user.add_role("merchant")

      @merchant = @user.build_merchant(merchant_params)

      if @merchant.save
        redirect_to merchants_path, notice: "Merchant created successfully."
      else
        @user.destroy
        render :new, status: :unprocessable_entity
      end
    else
      @merchant = Merchant.new(merchant_params)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @merchant.update(merchant_params)
      redirect_to merchants_path, notice: "Merchant updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @merchant.destroy
      redirect_to merchants_path, notice: "Merchant deleted successfully."
    else
      redirect_to merchants_path, alert: "Cannot delete merchant with existing transactions."
    end
  end

  def add_funds
    # Renders the add_funds form
  end

  def fund
    amount = params[:amount].to_f
    if amount <= 0
      flash.now[:alert] = "Amount must be greater than 0"
      render :add_funds, status: :unprocessable_entity
      return
    end

    amount_cents = (amount * 100).to_i

    ActiveRecord::Base.transaction do
      # 1. Create Payment record (Manual Load)
      payment = @merchant.payments.create!(
        amount_cents: amount_cents,
        currency: @merchant.currency,
        status: "completed",
        payment_method: "bank_transfer",
        gateway: "manual_load",
        description: "Manual balance load by admin",
        metadata: { loaded_by: current_user.email }
      )

      # 2. Create Transaction (Credit)
      @merchant.transactions.create!(
        payment: payment,
        amount_cents: amount_cents,
        balance_before_cents: @merchant.balance_cents,
        balance_after_cents: @merchant.balance_cents + amount_cents,
        transaction_type: "credit",
        status: "completed",
        currency: @merchant.currency,
        description: "Funds added by admin"
      )

      # 3. Update Merchant Balance
      @merchant.update!(balance_cents: @merchant.balance_cents + amount_cents)
    end

    redirect_to merchants_path, notice: "Successfully added #{amount} #{@merchant.currency} to merchant balance."
  rescue => e
    flash.now[:alert] = "Failed to add funds: #{e.message}"
    render :add_funds, status: :unprocessable_entity
  end

  private

  def set_merchant
    @merchant = Merchant.find(params[:id])
  end

  def require_admin
    unless current_user.has_role?("admin")
      redirect_to root_path, alert: "Access denied. Admin only."
    end
  end

  def user_params
    params.require(:user).permit(:email)
  end

  def merchant_params
    params.require(:merchant).permit(
      :company_name,
      :name,
      :email,
      :phone,
      :tax_id,
      :business_type,
      :status,
      :currency
    )
  end
end
