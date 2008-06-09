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

  def show
    @go_term = GoTerm.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  def summary
    @go_term = GoTerm.find(params[:id])
    @domains = @go_term.chains.map(&:domains)

    respond_to do |format|
      format.html { render :layout => false }
    end
  end

#  def propensities
#    @scop = Scop.send("rep#{@redundancy}").find(params[:id])
#
#    respond_to do |format|
#      format.html { render :layout => false }
#    end
#  end
#
#  def frequencies
#    @scop = Scop.send("rep#{@redundancy}").find(params[:id])
#
#    respond_to do |format|
#      format.html { render :layout => false }
#    end
#  end
#
#  def alignments
#    @scop = Scop.send("rep#{@redundancy}").find(params[:id])
#
#    respond_to do |format|
#      format.html { render :layout => false }
#    end
#  end
#
#  def interfaces
#    @scop = Scop.send("rep#{@redundancy}").find(params[:id])
#    @dna_interfaces = @scop.dna_interfaces(@redundancy, @resolution)
#    @rna_interfaces = @scop.rna_interfaces(@redundancy, @resolution)
#    @interfaces = @dna_interfaces + @rna_interfaces
#
#    respond_to do |format|
#      format.html { render :layout => false }
#    end
#  end

end
