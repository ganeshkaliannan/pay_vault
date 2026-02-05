class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.integer :amount_cents, null: false
      t.string :currency, default: 'USD', null: false
      t.string :transaction_type, null: false
      t.string :status, default: 'completed', null: false
      t.text :description
      t.integer :balance_before_cents, null: false
      t.integer :balance_after_cents, null: false
      t.references :merchant, null: false, foreign_key: true
      t.references :payment, null: true, foreign_key: true
      t.references :payout, null: true, foreign_key: true
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :transactions, [ :merchant_id, :created_at ]
    add_index :transactions, [ :merchant_id, :transaction_type ]
    add_index :transactions, :status
  end
end
