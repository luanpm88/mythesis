require 'test_helper'

class InfoboxTemplatesControllerTest < ActionController::TestCase
  setup do
    @infobox_template = infobox_templates(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:infobox_templates)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create infobox_template" do
    assert_difference('InfoboxTemplate.count') do
      post :create, infobox_template: { name: @infobox_template.name }
    end

    assert_redirected_to infobox_template_path(assigns(:infobox_template))
  end

  test "should show infobox_template" do
    get :show, id: @infobox_template
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @infobox_template
    assert_response :success
  end

  test "should update infobox_template" do
    patch :update, id: @infobox_template, infobox_template: { name: @infobox_template.name }
    assert_redirected_to infobox_template_path(assigns(:infobox_template))
  end

  test "should destroy infobox_template" do
    assert_difference('InfoboxTemplate.count', -1) do
      delete :destroy, id: @infobox_template
    end

    assert_redirected_to infobox_templates_path
  end
end
