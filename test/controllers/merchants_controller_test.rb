require "test_helper"

class MerchantsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get merchants_index_url
    assert_response :success
  end

  test "should get new" do
    get merchants_new_url
    assert_response :success
  end

  test "should get create" do
    get merchants_create_url
    assert_response :success
  end

  test "should get edit" do
    get merchants_edit_url
    assert_response :success
  end

  test "should get update" do
    get merchants_update_url
    assert_response :success
  end

  test "should get destroy" do
    get merchants_destroy_url
    assert_response :success
  end
end
