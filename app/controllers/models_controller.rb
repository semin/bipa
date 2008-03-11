class ModelsController < ApplicationController

  before_filter :get_structure

  def index
    @models = @structure.models.find(:all)

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @models.to_xml }
    end
  end

  def show
    @model = @structure.models.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @model.to_xml }
    end
  end


  private

  def get_structure
    @structure = Structure.find(params[:structure_id])
  end

end
