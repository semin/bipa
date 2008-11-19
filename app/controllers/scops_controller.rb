class ScopsController < ApplicationController

  def index
    @scops = ScopFamily.rpall.paginate(:page => params[:page] || 1, :per_page => 10)

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
    @hits = Scop.rpall.search(@query).compact

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
