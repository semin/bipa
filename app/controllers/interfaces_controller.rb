class InterfacesController < ApplicationController

  caches_page :show

  def index
    @interfaces = DomainInterface.all.paginate(:page => params[:page] || 1, :per_page => 10)

    respond_to do |format|
      format.html
    end
  end

  def show
    @interface = DomainInterface.find(params[:id])

    redirect_to :back unless @interface
    respond_to do |format|
      format.html
    end
  end

end
