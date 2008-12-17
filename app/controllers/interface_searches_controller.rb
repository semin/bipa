class InterfaceSearchesController < ApplicationController

  def show
    @interface_search = InterfaceSearch.find(params[:id])
    @interfaces       = @interface_search.find_interfaces.paginate(:page => params[:page], :per_page => 10)

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  def new
    @interface_search = InterfaceSearch.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def create
    @interface_search = InterfaceSearch.new(params[:interface_search])

    respond_to do |format|
      if @interface_search.save
        #flash[:notice] = 'InterfaceSearch.was successfully created.'
        format.html { redirect_to(@interface_search) }
      else
        format.html { render :action => "new" }
      end
    end
  end

end
