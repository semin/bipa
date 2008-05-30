class InterfacesController < ApplicationController

  def index
    case params[:interface_type] ||= "DomainInterface"
    when "DomainInterface"
      @type = "DomainInterface"
    when "ChainInterface"
      @type = "ChainInterface"
    end

    @interfaces = @type.constantize.paginate(:per_page => 10,
                                             :page => params[:page])

    respond_to do |format|
      format.html
    end
  end
end
