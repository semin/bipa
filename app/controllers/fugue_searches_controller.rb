class FugueSearchesController < ApplicationController

  # GET /fugue_searchs
  def index
    fugue_searches = FugueSearch.all

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @fugue_searchs.to_xml }
    end
  end

  # GET /fugue_searchs/1
  def show
    fugue_searches = FugueSearch.find(params[:id])
  end

  # GET /fugue_searchs/new
  def new
    @fugue_search = FugueSearch.new
  end

  # GET /fugue_searches/1;edit
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
        format.html { redirect_to fugue_search_url(@fugue_search) }
        format.xml  { head :created, :location => fugue_search_url(@fugue_search) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @fugue_search.errors.to_xml }
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
        format.html { redirect_to fugue_search_url(@fugue_search) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @fugue_search.errors.to_xml }
      end
    end
  end

  # DELETE /fugue_searches/1
  # DELETE /fugue_searches/1.xml
  def destroy
    @fugue_search = FugueSearch.find(params[:id])
    @fugue_search.destroy

    respond_to do |format|
      format.html { redirect_to fugue_searches_url }
      format.xml  { head :ok }
    end
  end

end
