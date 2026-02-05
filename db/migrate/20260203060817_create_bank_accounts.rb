class CreateBankAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :bank_accounts do |t|
      t.string :account_holder_name, null: false
      t.string :account_number, null: false
      t.string :routing_number
      t.string :bank_name, null: false
      t.string :bank_code
      t.string :account_type
      t.string :currency, default: 'USD', null: false
      t.boolean :is_verified, default: false, null: false
      t.boolean :is_primary, default: false, null: false
      t.references :accountable, polymorphic: true, null: false
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :bank_accounts, [ :accountable_type, :accountable_id, :is_primary ], name: 'index_bank_accounts_on_accountable_and_primary'
    add_index :bank_accounts, :is_verified
  end
end
