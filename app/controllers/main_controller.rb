class MainController < ApplicationController

  caches_page :home, :contact

  def home
    @structure = Structure.latest.first
    #@structure = Structure.find_by_pdb_code("1A36")

    respond_to do |format|
      format.html
    end
  end

  def contact
    respond_to do |format|
      format.html
    end
  end

  def search
    case params[:search_model]
    when "PDB"
      redirect_to :controller => "structures", :action => "search", :query => params[:query]
    when "SCOP"
      redirect_to :controller => "scops", :action => "search", :query => params[:query]
    else
      redirect_to "/"
    end
  end
end
