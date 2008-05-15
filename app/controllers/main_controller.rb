class MainController < ApplicationController

  def home
    respond_to do |format|
      format.html
    end
  end

  def contact
    respond_to do |format|
      format.html
    end
  end

  def scop_subtree
    children = Scop.find(params[:id]).registered_children

    children.each do |child|
      if child.children_count > 0
        child[:expanded] = true
      end
    end

    respond_to do |format|
      format.json { render :json => children.to_json }
    end
  end
end
