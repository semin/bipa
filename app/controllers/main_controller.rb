class MainController < ApplicationController

  caches_page :home, :references, :contact

  def home
    @structure    = Structure.latest.first
    @latest_news  = News.all[-3..-1].reverse

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
    @news = News.all.reverse
  end

end
