class InterfacesController < ApplicationController

  caches_page :show

  def index
    @interfaces = DomainInterface.all.paginate(:page => params[:page], :per_page => 10)

    respond_to do |format|
      format.html
    end
  end

  def show
    @interface = DomainInterface.find(params[:id])
    @similar_interfaces = @interface.sorted_similar_interfaces_in_usr(20)

    redirect_to :back unless @interface
    respond_to do |format|
      format.html
    end
  end

  def search
  end

end
