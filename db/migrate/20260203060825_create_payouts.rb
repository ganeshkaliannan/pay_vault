class CreatePayouts < ActiveRecord::Migration[8.1]
  def change
    create_table :payouts do |t|
      t.integer :amount_cents, null: false
      t.string :currency, default: 'USD', null: false
      t.string :status, default: 'pending', null: false
      t.string :payout_method
      t.references :bank_account, null: false, foreign_key: true
      t.references :merchant, null: false, foreign_key: true
      t.integer :fee_cents, default: 0, null: false
      t.datetime :scheduled_at
      t.datetime :processed_at
      t.datetime :completed_at
      t.text :failure_reason
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :payouts, [ :merchant_id, :status ]
    add_index :payouts, [ :merchant_id, :created_at ]
    add_index :payouts, :status
    add_index :payouts, :scheduled_at
  end
end
