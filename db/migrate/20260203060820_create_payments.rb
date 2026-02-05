class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.integer :amount_cents, null: false
      t.string :currency, default: 'USD', null: false
      t.string :status, default: 'pending', null: false
      t.string :payment_method
      t.string :gateway
      t.string :gateway_transaction_id
      t.text :description
      t.references :merchant, null: false, foreign_key: true
      t.jsonb :metadata, default: {}
      t.datetime :processed_at

      t.timestamps
    end

    add_index :payments, :status
    add_index :payments, :gateway_transaction_id, unique: true
    add_index :payments, [ :merchant_id, :status ]
    add_index :payments, [ :merchant_id, :created_at ]
  end
end
