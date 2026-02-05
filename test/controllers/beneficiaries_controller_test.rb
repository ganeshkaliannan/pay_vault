require "test_helper"

class BeneficiariesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get beneficiaries_index_url
    assert_response :success
  end

  test "should get new" do
    get beneficiaries_new_url
    assert_response :success
  end

  test "should get create" do
    get beneficiaries_create_url
    assert_response :success
  end

  test "should get edit" do
    get beneficiaries_edit_url
    assert_response :success
  end

  test "should get update" do
    get beneficiaries_update_url
    assert_response :success
  end

  test "should get destroy" do
    get beneficiaries_destroy_url
    assert_response :success
  end
end
