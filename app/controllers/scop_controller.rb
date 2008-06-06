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

  def frequencies
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

  def interfaces
    @scop = Scop.send("rep#{@redundancy}").find(params[:id])
    @dna_interfaces = @scop.dna_interfaces(@redundancy, @resolution)
    @rna_interfaces = @scop.rna_interfaces(@redundancy, @resolution)
    @interfaces = @dna_interfaces + @rna_interfaces

    respond_to do |format|
      format.html { render :layout => false }
    end
  end

end
