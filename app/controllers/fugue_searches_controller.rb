class FugueSearchesController < ApplicationController
  # GET /fugue_searches
  # GET /fugue_searches.xml
  def index
    @fugue_searches = FugueSearch.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @fugue_searches }
    end
  end

  # GET /fugue_searches/1
  # GET /fugue_searches/1.xml
  def show
    @fugue_search = FugueSearch.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @fugue_search }
    end
  end

  # GET /fugue_searches/new
  # GET /fugue_searches/new.xml
  def new
    @fugue_search = FugueSearch.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @fugue_search }
    end
  end

  # GET /fugue_searches/1/edit
  def edit
    @fugue_search = FugueSearch.find(params[:id])
  end

  # POST /fugue_searches
  # POST /fugue_searches.xml
  def create
    @fugue_search = FugueSearch.new(params[:fugue_search])

    respond_to do |format|
      if @fugue_search.save
        flash[:notice] = 'FugueSearch was successfully created.'
        format.html { redirect_to(@fugue_search) }
        format.xml  { render :xml => @fugue_search, :status => :created, :location => @fugue_search }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @fugue_search.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /fugue_searches/1
  # PUT /fugue_searches/1.xml
  def update
    @fugue_search = FugueSearch.find(params[:id])

    respond_to do |format|
      if @fugue_search.update_attributes(params[:fugue_search])
        flash[:notice] = 'FugueSearch was successfully updated.'
        format.html { redirect_to(@fugue_search) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @fugue_search.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /fugue_searches/1
  # DELETE /fugue_searches/1.xml
  def destroy
    @fugue_search = FugueSearch.find(params[:id])
    @fugue_search.destroy

    respond_to do |format|
      format.html { redirect_to(fugue_searches_url) }
      format.xml  { head :ok }
    end
  end
end
