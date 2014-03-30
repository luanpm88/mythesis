require 'test_helper'

class AttributeValuesControllerTest < ActionController::TestCase
  setup do
    @attribute_value = attribute_values(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:attribute_values)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create attribute_value" do
    assert_difference('AttributeValue.count') do
      post :create, attribute_value: { article_id: @attribute_value.article_id, attribute_id: @attribute_value.attribute_id, value: @attribute_value.value }
    end

    assert_redirected_to attribute_value_path(assigns(:attribute_value))
  end

  test "should show attribute_value" do
    get :show, id: @attribute_value
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @attribute_value
    assert_response :success
  end

  test "should update attribute_value" do
    patch :update, id: @attribute_value, attribute_value: { article_id: @attribute_value.article_id, attribute_id: @attribute_value.attribute_id, value: @attribute_value.value }
    assert_redirected_to attribute_value_path(assigns(:attribute_value))
  end

  test "should destroy attribute_value" do
    assert_difference('AttributeValue.count', -1) do
      delete :destroy, id: @attribute_value
    end

    assert_redirected_to attribute_values_path
  end
end
