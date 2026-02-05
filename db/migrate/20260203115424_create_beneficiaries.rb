class CreateBeneficiaries < ActiveRecord::Migration[8.1]
  def change
    create_table :beneficiaries do |t|
      t.references :merchant, null: false, foreign_key: true
      t.string :name, null: false
      t.string :account_number, null: false
      t.string :ifsc_code, null: false
      t.string :bank_name, null: false
      t.string :branch_name
      t.string :account_type, default: 'savings', null: false
      t.string :email
      t.string :phone
      t.string :status, default: 'active', null: false
      t.boolean :is_verified, default: false, null: false
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :beneficiaries, :merchant_id
    add_index :beneficiaries, :status
    add_index :beneficiaries, [ :merchant_id, :status ]
    add_index :beneficiaries, :account_number
  end
end
