class InterfacesController < ApplicationController

  def index
    case params[:interface_type] ||= "DomainInterface"
    when "DomainInterface"
      @type = "DomainInterface"
    when "ChainInterface"
      @type = "ChainInterface"
    end

    @interfaces = @type.constantize.paginate(:per_page => 20,
                                             :page => params[:page])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @interfaces }
    end
  end
end
