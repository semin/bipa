class MainController < ApplicationController

  def home
    @newses = News.find(:all)

    respond_to do |format|
      format.html
    end
  end

  def browse
    redirect_to :controller => "interfaces", :action => "index"
  end

  def search
  end

  def contact
    respond_to do |format|
      format.html
    end
  end
end
