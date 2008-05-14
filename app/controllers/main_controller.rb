class MainController < ApplicationController

  def home
#    @scop_tree ||= Scop.root.ul_tree

    respond_to do |format|
      format.html
    end
  end

  def contact
    respond_to do |format|
      format.html
    end
  end

  def scop_children
    @children = Scop.registered.find(params[:id]).registered_children

    respond_to do |format|
      format.json { render :json => @children.to_json }
    end
  end
end
