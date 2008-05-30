class InterfacesController < ApplicationController

  def index
    case params[:type] ||= "DomainInterface"
    when "DomainInterface"
      @type = "DomainInterface"
    when "ChainInterface"
      @type = "ChainInterface"
    end

    @interfaces = @type.constantize.paginate(:per_page => 15,
                                             :page => params[:page])

    respond_to do |format|
      format.html
      format.js { render :template => "index.html.erb" }
    end
  end
end
