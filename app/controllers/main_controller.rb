class MainController < ApplicationController

  caches_page :home

  def home
    @structure    = Structure.latest.first
    @latest_news  = News.order('date desc').limit(5)

    respond_to do |format|
      format.html
    end
  end

  def references
    respond_to do |format|
      format.html
    end
  end

  def contact
    respond_to do |format|
      format.html
    end
  end

  def news
    @news = News.order('date desc')
  end

  def search
    case params[:search_model]
    when "PDB"
      redirect_to :controller => "structures", :action => "search", :query => params[:query]
    when "SCOP"
      redirect_to :controller => "scops", :action => "search", :query => params[:query]
    else
      redirect_to "/"
    end
  end
end
