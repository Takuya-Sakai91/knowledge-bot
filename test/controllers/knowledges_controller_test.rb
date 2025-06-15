require "test_helper"

class KnowledgesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @knowledge = knowledges(:one)
  end

  test "should get index" do
    get knowledges_url, as: :json
    assert_response :success
  end

  test "should create knowledge" do
    assert_difference("Knowledge.count") do
      post knowledges_url, params: { knowledge: { category: @knowledge.category, content: @knowledge.content, keyword: @knowledge.keyword } }, as: :json
    end

    assert_response :created
  end

  test "should show knowledge" do
    get knowledge_url(@knowledge), as: :json
    assert_response :success
  end

  test "should update knowledge" do
    patch knowledge_url(@knowledge), params: { knowledge: { category: @knowledge.category, content: @knowledge.content, keyword: @knowledge.keyword } }, as: :json
    assert_response :success
  end

  test "should destroy knowledge" do
    assert_difference("Knowledge.count", -1) do
      delete knowledge_url(@knowledge), as: :json
    end

    assert_response :no_content
  end
end
