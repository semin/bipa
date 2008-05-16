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
    children = Scop.find(params[:root]).registered_children

    children.each do |child|
      if child.registered_children.size > 0
        child[:hasChildren] = true
      end
    end

    respond_to do |format|
      format.json { render :json => children.to_json }
    end
  end
end
