class StructuresController < ApplicationController

  caches_page :show

  def index
    @structures = Structure.untainted.paginate(:page => params[:page] || 1, :per_page => 10)

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

end
