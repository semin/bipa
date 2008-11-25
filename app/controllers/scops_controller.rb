class ScopsController < ApplicationController

  def index
    @scops = ScopDomain.rpall.paginate(:page => params[:page] || 1,
                                       :per_page => 20)

    respond_to do |format|
      format.html
    end
  end

  def show
    @scop = Scop.find(params[:id])

    if @scop.is_a? ScopDomain
      respond_to do |format|
        format.html
      end
    else
      redirect_to hierarchy_scop_path(@scop)
    end
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
