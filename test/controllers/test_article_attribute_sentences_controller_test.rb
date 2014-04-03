require 'test_helper'

class TestArticleAttributeSentencesControllerTest < ActionController::TestCase
  setup do
    @test_article_attribute_sentence = test_article_attribute_sentences(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:test_article_attribute_sentences)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create test_article_attribute_sentence" do
    assert_difference('TestArticleAttributeSentence.count') do
      post :create, test_article_attribute_sentence: { article_id: @test_article_attribute_sentence.article_id, attribute_id: @test_article_attribute_sentence.attribute_id, sentence: @test_article_attribute_sentence.sentence }
    end

    assert_redirected_to test_article_attribute_sentence_path(assigns(:test_article_attribute_sentence))
  end

  test "should show test_article_attribute_sentence" do
    get :show, id: @test_article_attribute_sentence
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @test_article_attribute_sentence
    assert_response :success
  end

  test "should update test_article_attribute_sentence" do
    patch :update, id: @test_article_attribute_sentence, test_article_attribute_sentence: { article_id: @test_article_attribute_sentence.article_id, attribute_id: @test_article_attribute_sentence.attribute_id, sentence: @test_article_attribute_sentence.sentence }
    assert_redirected_to test_article_attribute_sentence_path(assigns(:test_article_attribute_sentence))
  end

  test "should destroy test_article_attribute_sentence" do
    assert_difference('TestArticleAttributeSentence.count', -1) do
      delete :destroy, id: @test_article_attribute_sentence
    end

    assert_redirected_to test_article_attribute_sentences_path
  end
end
