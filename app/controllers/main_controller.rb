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
end
