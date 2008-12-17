require 'test_helper'

class InterfaceSearchesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:interface_searches)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create interface_searches" do
    assert_difference('InterfaceSearches.count') do
      post :create, :interface_searches => { }
    end

    assert_redirected_to interface_searches_path(assigns(:interface_searches))
  end

  test "should show interface_searches" do
    get :show, :id => interface_searches(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => interface_searches(:one).id
    assert_response :success
  end

  test "should update interface_searches" do
    put :update, :id => interface_searches(:one).id, :interface_searches => { }
    assert_redirected_to interface_searches_path(assigns(:interface_searches))
  end

  test "should destroy interface_searches" do
    assert_difference('InterfaceSearches.count', -1) do
      delete :destroy, :id => interface_searches(:one).id
    end

    assert_redirected_to interface_searches_path
  end
end
