class CreateMerchants < ActiveRecord::Migration[8.1]
  def change
    create_table :merchants do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone
      t.string :company_name, null: false
      t.string :tax_id
      t.string :business_type
      t.string :status, default: 'pending', null: false
      t.integer :balance_cents, default: 0, null: false
      t.string :currency, default: 'USD', null: false
      t.jsonb :settings, default: {}
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :merchants, :email, unique: true
    add_index :merchants, :status
    add_index :merchants, :created_at
  end
end
