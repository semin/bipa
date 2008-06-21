class InterfacesController < ApplicationController

  before_filter :find_scop, :only => :index

  def index
    @interfaces = @scop.interfaces(session[:redundancy], session[:resolution])

    respond_to do |format|
      format.html
    end
  end

  def show
    @interface = Interface.find(params[:id])

    redirect_to :back unless @interface
    respond_to do |format|
      format.html
    end
  end

  private

  def find_scop
    @scop_id = params[:scop_id]

    redirect_to :back unless @scop_id
    @scop = Scop.find(@scop_id)
  end
end
