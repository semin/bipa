class MainController < ApplicationController

  def home
    @newses = News.find(:all)

    respond_to do |format|
      format.html
    end
  end

  def contact
    respond_to do |format|
      format.html
    end
  end
end
