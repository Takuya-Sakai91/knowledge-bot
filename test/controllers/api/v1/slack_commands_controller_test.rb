require "test_helper"

class Api::V1::SlackCommandsControllerTest < ActionDispatch::IntegrationTest
  test "should get commands" do
    get api_v1_slack_commands_commands_url
    assert_response :success
  end
end
