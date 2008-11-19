class MainController < ApplicationController

  def home
    #@structure = Structure.latest.first
    @structure = Structure.find_by_pdb_code("1A36")

    respond_to do |format|
      format.html
    end
  end

  def browse
    case params[:classification]
    when "PDB"
      redirect_to structures_url
    when "SCOP"
      redirect_to scops_url
    when "GO"
      redirect_to gos_url
    when "TAXONOMY"
      redirect_to taxa_url
    end
  end

  def contact
    respond_to do |format|
      format.html
    end
  end
end
