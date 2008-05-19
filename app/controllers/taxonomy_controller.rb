class TaxonomyController < ApplicationController

  def children
    children = TaxonomicNode.find(params[:root]).children

    children.each do |child|
      child[:tree_title] = child.tree_title
      if child.children.size > 0
        child[:hasChildren] = true
      end
    end

    respond_to do |format|
      format.json { render :json => children.to_json }
    end
  end
end
