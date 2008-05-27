class ScopController < ApplicationController

  def children
    if params[:root] == "root"
      children = Scop.find(1).registered_children
    else
      children = Scop.repall.find(params[:root]).registered_children
    end

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

  def tabs
    @scop = Scop.repall.find(params[:id])

    respond_to do |format|
      format.html { render :layout => false }
    end
  end

  def summary
    @scop = Scop.repall.find(params[:id])

    respond_to do |format|
      format.html { render :layout => false }
    end
  end

  def propensity
    @scop = Scop.repall.find(params[:id])

    respond_to do |format|
      format.html { render :layout => false }
    end
  end

  def msa
    @scop = Scop.repall.find(params[:id])

    respond_to do |format|
      format.html { render :layout => false }
    end
  end

  def esst
    @scop = Scop.repall.find(params[:id])

    respond_to do |format|
      format.html { render :layout => false }
    end
  end
end
