class ResiduesController < ApplicationController

  before_filter :get_chain

  # GET /residues
  # GET /residues.xml
  def index
    @residues = @chain.residues.find(:all)

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @residues.to_xml }
    end
  end

  # GET /residues/1
  # GET /residues/1.xml
  def show
    @residue = @chain.residues.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @residue.to_xml }
    end
  end


  private

  def get_chain
    @chain = Chain.find(params[:chain_id])
  end
end
