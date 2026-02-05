# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Seeding database..."

# Create default roles
puts "Creating roles..."
roles = [ 'admin', 'merchant' ]
roles.each do |role_name|
  Role.find_or_create_by!(name: role_name)
end

# Create admin user
puts "Creating admin user..."
admin_user = User.find_or_create_by!(email: 'admin@payvault.com') do |user|
  user.password = 'Admin@123'
  user.password_confirmation = 'Admin@123'
end
admin_user.add_role('admin')

# Create merchant users and merchants
puts "Creating merchants..."

merchant1_user = User.find_or_create_by!(email: 'merchant1@example.com') do |user|
  user.password = 'Merchant@123'
  user.password_confirmation = 'Merchant@123'
end
merchant1_user.add_role('merchant')

merchant1 = Merchant.find_or_create_by!(email: 'merchant1@example.com') do |m|
  m.user = merchant1_user
  m.name = 'Tech Solutions Inc'
  m.company_name = 'Tech Solutions Inc'
  m.phone = '+1-555-0101'
  m.tax_id = 'TAX123456'
  m.business_type = 'llc'
  m.status = 'active'
  m.balance_cents = 50000_00 # $50,000
  m.currency = 'USD'
  m.settings = {
    payout_schedule: 'weekly',
    minimum_payout_amount: 10000, # $100
    auto_payout_enabled: false
  }
end

merchant2_user = User.find_or_create_by!(email: 'merchant2@example.com') do |user|
  user.password = 'Merchant@123'
  user.password_confirmation = 'Merchant@123'
end
merchant2_user.add_role('merchant')

merchant2 = Merchant.find_or_create_by!(email: 'merchant2@example.com') do |m|
  m.user = merchant2_user
  m.name = 'E-Commerce Store'
  m.company_name = 'E-Commerce Store LLC'
  m.phone = '+1-555-0102'
  m.tax_id = 'TAX789012'
  m.business_type = 'llc'
  m.status = 'active'
  m.balance_cents = 25000_00 # $25,000
  m.currency = 'USD'
  m.settings = {
    payout_schedule: 'daily',
    minimum_payout_amount: 5000, # $50
    auto_payout_enabled: true
  }
end

# Create bank accounts for merchants
puts "Creating bank accounts..."

bank1 = BankAccount.find_or_create_by!(
  accountable: merchant1,
  account_number: '1234567890'
) do |ba|
  ba.account_holder_name = 'Tech Solutions Inc'
  ba.routing_number = '021000021'
  ba.bank_name = 'Chase Bank'
  ba.bank_code = 'CHASE'
  ba.account_type = 'current'
  ba.currency = 'USD'
  ba.is_verified = true
  ba.is_primary = true
end

bank2 = BankAccount.find_or_create_by!(
  accountable: merchant2,
  account_number: '0987654321'
) do |ba|
  ba.account_holder_name = 'E-Commerce Store LLC'
  ba.routing_number = '026009593'
  ba.bank_name = 'Bank of America'
  ba.bank_code = 'BOA'
  ba.account_type = 'current'
  ba.currency = 'USD'
  ba.is_verified = true
  ba.is_primary = true
end

# Create payments
puts "Creating payments..."

Payment.create!(
  merchant: merchant1,
  amount_cents: 25000, # $250
  currency: 'USD',
  status: 'completed',
  payment_method: 'card',
  gateway: 'stripe',
  gateway_transaction_id: 'ch_stripe_001',
  description: 'Product purchase',
  processed_at: 2.days.ago,
  metadata: {
    customer_name: 'John Doe',
    customer_email: 'john.doe@example.com'
  }
)

Payment.create!(
  merchant: merchant1,
  amount_cents: 125050, # $1,250.50
  currency: 'USD',
  status: 'completed',
  payment_method: 'upi',
  gateway: 'razorpay',
  gateway_transaction_id: 'pay_razorpay_002',
  description: 'Service subscription',
  processed_at: 1.day.ago,
  metadata: {
    customer_name: 'Jane Smith',
    customer_email: 'jane.smith@example.com'
  }
)

Payment.create!(
  merchant: merchant2,
  amount_cents: 50000, # $500
  currency: 'USD',
  status: 'completed',
  payment_method: 'bank_transfer',
  gateway: 'city_union_bank',
  gateway_transaction_id: 'cub_003',
  description: 'Online order',
  processed_at: 3.hours.ago,
  metadata: {
    customer_name: 'Bob Johnson',
    customer_email: 'bob.johnson@example.com'
  }
)

Payment.create!(
  merchant: merchant1,
  amount_cents: 75025, # $750.25
  currency: 'USD',
  status: 'pending',
  payment_method: 'card',
  gateway: 'stripe',
  gateway_transaction_id: 'ch_stripe_004',
  description: 'Pending payment',
  metadata: {
    customer_name: 'Alice Brown',
    customer_email: 'alice.brown@example.com'
  }
)

# Create payouts
puts "Creating payouts..."

payout1 = Payout.create!(
  merchant: merchant1,
  bank_account: bank1,
  amount_cents: 10000_00, # $10,000
  currency: 'USD',
  status: 'completed',
  payout_method: 'neft',
  fee_cents: 100, # $1 fee
  scheduled_at: 5.days.ago,
  processed_at: 5.days.ago,
  completed_at: 4.days.ago
)

payout2 = Payout.create!(
  merchant: merchant2,
  bank_account: bank2,
  amount_cents: 5000_00, # $5,000
  currency: 'USD',
  status: 'pending',
  payout_method: 'imps',
  fee_cents: 50, # $0.50 fee
  scheduled_at: Time.current
)

puts "✅ Seed data created successfully!"
puts ""
puts "📊 Summary:"
puts "  - #{User.count} users"
puts "  - #{Merchant.count} merchants"
puts "  - #{Payment.count} payments"
puts "  - #{Payout.count} payouts"
puts "  - #{Transaction.count} transactions"
puts "  - #{BankAccount.count} bank accounts"
puts ""
puts "🔑 Login Credentials:"
puts "  Admin: admin@payvault.com / Admin@123"
puts "  Merchant 1: merchant1@example.com / Merchant@123"
puts "  Merchant 2: merchant2@example.com / Merchant@123"
