class StructuresController < ApplicationController

  def index
    @structures = Structure.untainted.paginate(:page => params[:page] || 1, :per_page => 10)

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @structures.to_xml }
    end
  end

  # GET /structures/1
  # GET /structures/1.xml
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

#  # GET /structures/new
#  def new
#    @structure = Structure.new
#  end

#  # GET /structures/1;edit
#  def edit
#    @structure = Structure.find(params[:id])
#  end

#  # POST /structures
#  # POST /structures.xml
#  def create
#    @structure = Structure.new(params[:structure])
#
#    respond_to do |format|
#      if @structure.save
#        flash[:notice] = 'Structure was successfully created.'
#        format.html { redirect_to structure_url(@structure) }
#        format.xml  { head :created, :location => structure_url(@structure) }
#      else
#        format.html { render :action => "new" }
#        format.xml  { render :xml => @structure.errors.to_xml }
#      end
#    end
#  end

#  # PUT /structures/1
#  # PUT /structures/1.xml
#  def update
#    @structure = Structure.find(params[:id])
#
#    respond_to do |format|
#      if @structure.update_attributes(params[:structure])
#        flash[:notice] = 'Structure was successfully updated.'
#        format.html { redirect_to structure_url(@structure) }
#        format.xml  { head :ok }
#      else
#        format.html { render :action => "edit" }
#        format.xml  { render :xml => @structure.errors.to_xml }
#      end
#    end
#  end

#  # DELETE /structures/1
#  # DELETE /structures/1.xml
#  def destroy
#    @structure = Structure.find(params[:id])
#    @structure.destroy
#
#    respond_to do |format|
#      format.html { redirect_to structures_url }
#      format.xml  { head :ok }
#    end
#  end
end
