class BeneficiariesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_merchant
  before_action :set_beneficiary, only: [ :edit, :update, :destroy, :verify ]

  def index
    @beneficiaries = current_user.merchant.beneficiaries.order(created_at: :desc).page(params[:page]).per(10)
  end

  def new
    @beneficiary = current_user.merchant.beneficiaries.new
  end

  def create
    @beneficiary = current_user.merchant.beneficiaries.new(beneficiary_params)

    # Auto-verify for now since we don't have real banking API
    @beneficiary.is_verified = true

    if @beneficiary.save
      redirect_to beneficiaries_path, notice: "Beneficiary added successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @beneficiary.update(beneficiary_params)
      redirect_to beneficiaries_path, notice: "Beneficiary updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @beneficiary.destroy
      redirect_to beneficiaries_path, notice: "Beneficiary removed successfully."
    else
      # If we can't delete (e.g. valid payouts exist), we deactivate
      if @beneficiary.update(status: "inactive")
        redirect_to beneficiaries_path, notice: "Beneficiary deactivated (could not delete due to existing history)."
      else
        redirect_to beneficiaries_path, alert: "Could not delete or deactivate beneficiary."
      end
    end
  end

  def verify
    @beneficiary.verify!
    redirect_to beneficiaries_path, notice: "Beneficiary verified successfully."
  end

  private

  def require_merchant
    unless current_user.has_role?("merchant") && current_user.merchant.present?
      redirect_to root_path, alert: "Access denied. Merchant account required."
    end
  end

  def set_beneficiary
    @beneficiary = current_user.merchant.beneficiaries.find(params[:id])
  end

  def beneficiary_params
    params.require(:beneficiary).permit(
      :name,
      :account_number,
      :ifsc_code,
      :bank_name,
      :branch_name,
      :account_type,
      :email,
      :phone
    )
  end
end
