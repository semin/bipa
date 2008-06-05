class ScopController < ApplicationController

  def children
    root = params[:root]

    if root == "root"
      children = Scop.send("rep#{@redundancy}").find(1).registered_children(@redundancy)
    else
      children = Scop.send("rep#{@redundancy}").find(root).registered_children(@redundancy)
    end

    children.each do |child|
      child[:tree_title] = child.tree_title
      if child.registered_children(@redundancy).size > 0
        child[:hasChildren] = true
      end
    end

    respond_to do |format|
      format.json { render :json => children.to_json }
    end
  end

  def show
    id = params[:id]
    @scop = Scop.send("rep#{@redundancy}").find(id)

    respond_to do |format|
      format.js
      format.html { render :layout => false }
    end
  end

  def summary
    @scop = Scop.send("rep#{@redundancy}").find(params[:id])

    respond_to do |format|
      format.html { render :layout => false }
    end
  end

  def propensities
    @scop = Scop.send("rep#{@redundancy}").find(params[:id])

    respond_to do |format|
      format.html { render :layout => false }
    end
  end

  def distributions
    @scop = Scop.send("rep#{@redundancy}").find(params[:id])

    respond_to do |format|
      format.html { render :layout => false }
    end
  end

  def alignments
    @scop = Scop.send("rep#{@redundancy}").find(params[:id])

    respond_to do |format|
      format.html { render :layout => false }
    end
  end

  def profiles
    @scop = Scop.send("rep#{@redundancy}").find(params[:id])

    respond_to do |format|
      format.html { render :layout => false }
    end
  end
end
