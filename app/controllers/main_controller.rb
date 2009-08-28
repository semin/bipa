class MainController < ApplicationController

  caches_page :home, :references, :contact

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

end
