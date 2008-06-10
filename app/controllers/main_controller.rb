class MainController < ApplicationController

  def home
    @newses = News.find(:all)

    respond_to do |format|
      format.html
    end
  end

  def browse
    session[:classification] = params[:classification]

    case params[:classification]
    when "SCOP"
      redirect_to scops_url
    when "GO"
      redirect_to gos_url
    when "TAXONOMY"
      redirect_to taxa_url
    when "INTERFACES"
      redirect_to interfaces_url
    end
  end

  def contact
    respond_to do |format|
      format.html
    end
  end
end
