class AddBeneficiaryToPayouts < ActiveRecord::Migration[8.1]
  def change
    add_reference :payouts, :beneficiary, null: true, foreign_key: true
    add_index :payouts, [ :merchant_id, :beneficiary_id ]
  end
end
