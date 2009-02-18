class StructuresController < ApplicationController

  caches_page :show

  def index
    @structures = Structure.untainted.paginate(:page => params[:page], :per_page => 10)

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @structures.to_xml }
    end
  end

  def show
    @structure  = Structure.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @structure.to_xml }
    end
  end

  def jmol
    @structure = Structure.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
    end
  end

  def search
    @query      = params[:query]
    @structures = Structure.untainted.search(@query, :page => params[:page], :per_page => 10).compact

    respond_to do |format|
      format.html
    end
  end
end
