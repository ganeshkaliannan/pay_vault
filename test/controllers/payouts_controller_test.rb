require "test_helper"

class PayoutsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get payouts_index_url
    assert_response :success
  end

  test "should get new" do
    get payouts_new_url
    assert_response :success
  end

  test "should get create" do
    get payouts_create_url
    assert_response :success
  end

  test "should get show" do
    get payouts_show_url
    assert_response :success
  end
end
