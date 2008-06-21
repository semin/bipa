class ScopsController < ApplicationController

  def index
    @scops = Scop.send("rep#{session[:redundancy]}").
                  send("res#{session[:resolution]}").
                  paginate(
                    :per_page => session[:per_page] || 10,
                    :page => params[:page] || 1)

    respond_to do |format|
      format.html
    end
  end

  def show
    @scop = Scop.find(params[:id])
    redirect_to hierarchy_scop_path(@scop)
  end

  def search
    @query = params[:query]
    @hits = Scop.search(@query)

    respond_to do |format|
      format.html
    end
  end

  def hierarchy
    @scop = Scop.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  def distributions
    @scop = Scop.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  def propensities
    @scop = Scop.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  def chisquare_test
    @scop = Scop.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

end
