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
    case params[:classification]
    when "SCOP"
      redirect_to params.merge(:controller => "scop", :action => "search")
    when "GO"
      redirect_to :controller => "go", :action => "search"
    when "TAXONOMY"
      redirect_to :controller => "taxonomy", :action => "search"
    else; raise "Unknow classification: #{params[:classification]}"
    end
  end

  def contact
    respond_to do |format|
      format.html
    end
  end
end
