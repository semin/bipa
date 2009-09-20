class StructuresController < ApplicationController

  caches_page :show, :jmol

  def index
    @query = params[:query]

    if @query && !@query.empty?
      @structures = Structure.untainted.search(@query, :match_mode => :extended, :page => params[:page], :per_page => 10).compact
    else
      @structures = Structure.untainted.paginate(:page => params[:page], :per_page => 10)
    end

    respond_to do |format|
      format.html
    end
  end

  def show
    @structure  = Structure.find_by_pdb_code(params[:id].upcase)

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @structure.to_xml }
    end
  end

  def jmol
    @structure = Structure.find_by_pdb_code(params[:id])

    respond_to do |format|
      format.html # show.rhtml
    end
  end

end
