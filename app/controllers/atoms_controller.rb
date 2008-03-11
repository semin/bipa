class AtomsController < ApplicationController

  before_filter :get_residue

  # GET /atoms
  # GET /atoms.xml
  def index
    @atoms = @residue.atoms.find(:all)

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @atoms.to_xml }
    end
  end

  # GET /atoms/1
  # GET /atoms/1.xml
  def show
    @atom = @residue.atoms.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @atom.to_xml }
    end
  end


  private

  def get_residue
    @residue = Residue.find(params[:residue_id])
  end

end
