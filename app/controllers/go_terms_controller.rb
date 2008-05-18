class GoTermsController < ApplicationController

  def chilren
    children = GoTerm.registered.find(params[:root]).registered_children

    children.each do |child|
      child[:tree_title] = child.tree_title
      if child.registered_children.size > 0
        child[:hasChildren] = true
      end
    end

    respond_to do |format|
      format.json { render :json => children.to_json }
    end
  end
end
