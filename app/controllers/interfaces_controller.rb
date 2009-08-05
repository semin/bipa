class InterfacesController < ApplicationController

  #caches_page :show

  def show
    @interface = DomainInterface.find(params[:id])
    @similar_interfaces = @interface.sorted_similar_interfaces_in_usr

    respond_to do |format|
      format.html
    end
  end

end
