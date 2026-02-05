# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_03_115427) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.bigint "merchant_id"
    t.jsonb "metadata", default: {}
    t.integer "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.text "user_agent"
    t.bigint "user_id", null: false
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["merchant_id", "created_at"], name: "index_audit_logs_on_merchant_id_and_created_at"
    t.index ["merchant_id"], name: "index_audit_logs_on_merchant_id"
    t.index ["resource_type", "resource_id"], name: "index_audit_logs_on_resource_type_and_resource_id"
    t.index ["user_id", "created_at"], name: "index_audit_logs_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "bank_accounts", force: :cascade do |t|
    t.string "account_holder_name", null: false
    t.string "account_number", null: false
    t.string "account_type"
    t.bigint "accountable_id", null: false
    t.string "accountable_type", null: false
    t.string "bank_code"
    t.string "bank_name", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "USD", null: false
    t.boolean "is_primary", default: false, null: false
    t.boolean "is_verified", default: false, null: false
    t.jsonb "metadata", default: {}
    t.string "routing_number"
    t.datetime "updated_at", null: false
    t.index ["accountable_type", "accountable_id", "is_primary"], name: "index_bank_accounts_on_accountable_and_primary"
    t.index ["accountable_type", "accountable_id"], name: "index_bank_accounts_on_accountable"
    t.index ["is_verified"], name: "index_bank_accounts_on_is_verified"
  end

  create_table "beneficiaries", force: :cascade do |t|
    t.string "account_number"
    t.string "account_type"
    t.string "bank_name"
    t.string "branch_name"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "ifsc_code"
    t.boolean "is_verified"
    t.bigint "merchant_id", null: false
    t.jsonb "metadata"
    t.string "name"
    t.string "phone"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["merchant_id"], name: "index_beneficiaries_on_merchant_id"
  end

  create_table "merchants", force: :cascade do |t|
    t.integer "balance_cents", default: 0, null: false
    t.string "business_type"
    t.string "company_name", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "USD", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "phone"
    t.jsonb "settings", default: {}
    t.string "status", default: "pending", null: false
    t.string "tax_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["created_at"], name: "index_merchants_on_created_at"
    t.index ["email"], name: "index_merchants_on_email", unique: true
    t.index ["status"], name: "index_merchants_on_status"
    t.index ["user_id"], name: "index_merchants_on_user_id"
  end

  create_table "payments", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "USD", null: false
    t.text "description"
    t.string "gateway"
    t.string "gateway_transaction_id"
    t.bigint "merchant_id", null: false
    t.jsonb "metadata", default: {}
    t.string "payment_method"
    t.datetime "processed_at"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["gateway_transaction_id"], name: "index_payments_on_gateway_transaction_id", unique: true
    t.index ["merchant_id", "created_at"], name: "index_payments_on_merchant_id_and_created_at"
    t.index ["merchant_id", "status"], name: "index_payments_on_merchant_id_and_status"
    t.index ["merchant_id"], name: "index_payments_on_merchant_id"
    t.index ["status"], name: "index_payments_on_status"
  end

  create_table "payouts", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.bigint "bank_account_id", null: false
    t.bigint "beneficiary_id"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "currency", default: "USD", null: false
    t.text "failure_reason"
    t.integer "fee_cents", default: 0, null: false
    t.bigint "merchant_id", null: false
    t.jsonb "metadata", default: {}
    t.string "payout_method"
    t.datetime "processed_at"
    t.datetime "scheduled_at"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["bank_account_id"], name: "index_payouts_on_bank_account_id"
    t.index ["beneficiary_id"], name: "index_payouts_on_beneficiary_id"
    t.index ["merchant_id", "beneficiary_id"], name: "index_payouts_on_merchant_id_and_beneficiary_id"
    t.index ["merchant_id", "created_at"], name: "index_payouts_on_merchant_id_and_created_at"
    t.index ["merchant_id", "status"], name: "index_payouts_on_merchant_id_and_status"
    t.index ["merchant_id"], name: "index_payouts_on_merchant_id"
    t.index ["scheduled_at"], name: "index_payouts_on_scheduled_at"
    t.index ["status"], name: "index_payouts_on_status"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "transactions", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.integer "balance_after_cents", null: false
    t.integer "balance_before_cents", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "USD", null: false
    t.text "description"
    t.bigint "merchant_id", null: false
    t.jsonb "metadata", default: {}
    t.bigint "payment_id"
    t.bigint "payout_id"
    t.string "status", default: "completed", null: false
    t.string "transaction_type", null: false
    t.datetime "updated_at", null: false
    t.index ["merchant_id", "created_at"], name: "index_transactions_on_merchant_id_and_created_at"
    t.index ["merchant_id", "transaction_type"], name: "index_transactions_on_merchant_id_and_transaction_type"
    t.index ["merchant_id"], name: "index_transactions_on_merchant_id"
    t.index ["payment_id"], name: "index_transactions_on_payment_id"
    t.index ["payout_id"], name: "index_transactions_on_payout_id"
    t.index ["status"], name: "index_transactions_on_status"
  end

  create_table "user_roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "audit_logs", "merchants"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "beneficiaries", "merchants"
  add_foreign_key "merchants", "users"
  add_foreign_key "payments", "merchants"
  add_foreign_key "payouts", "bank_accounts"
  add_foreign_key "payouts", "beneficiaries"
  add_foreign_key "payouts", "merchants"
  add_foreign_key "transactions", "merchants"
  add_foreign_key "transactions", "payments"
  add_foreign_key "transactions", "payouts"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
end
