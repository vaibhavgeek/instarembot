require 'test_helper'

class BotControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get bot_index_url
    assert_response :success
  end

  test "should get show" do
    get bot_show_url
    assert_response :success
  end

  test "should get create" do
    get bot_create_url
    assert_response :success
  end

  test "should get new" do
    get bot_new_url
    assert_response :success
  end

end
