class GoController < ApplicationController

  def children
    if params[:root] == "root"
      children = []
      children << GoTerm.find_by_go_id("GO:0003674") # molecular function
      children << GoTerm.find_by_go_id("GO:0005575") # cellular component
      children << GoTerm.find_by_go_id("GO:0008150") # biological process
    else
      children = GoTerm.find(params[:root]).sources
    end

    children.each do |child|
      child[:tree_title] = child.tree_title
      if child.sources.size > 0
        child[:hasChildren] = true
      end
    end

    respond_to do |format|
      format.json { render :json => children.to_json }
    end
  end

  def tabs
    @go_term = GoTerm.find(params[:id])

    respond_to do |format|
      format.html
    end
  end
end
