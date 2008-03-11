class ChainsController < ApplicationController

  before_filter :get_model

  def index
    @chains = @model.chains.find(:all)

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @chains.to_xml }
    end
  end

  def show
    @chain = @model.chains.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @chain.to_xml }
    end
  end


  private

  def get_model
    @model = Model.find(params[:model_id])
  end

end
