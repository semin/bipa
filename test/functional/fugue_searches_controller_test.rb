require 'test_helper'

class FugueSearchesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:fugue_searches)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create fugue_search" do
    assert_difference('FugueSearch.count') do
      post :create, :fugue_search => { }
    end

    assert_redirected_to fugue_search_path(assigns(:fugue_search))
  end

  test "should show fugue_search" do
    get :show, :id => fugue_searches(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => fugue_searches(:one).id
    assert_response :success
  end

  test "should update fugue_search" do
    put :update, :id => fugue_searches(:one).id, :fugue_search => { }
    assert_redirected_to fugue_search_path(assigns(:fugue_search))
  end

  test "should destroy fugue_search" do
    assert_difference('FugueSearch.count', -1) do
      delete :destroy, :id => fugue_searches(:one).id
    end

    assert_redirected_to fugue_searches_path
  end
end
