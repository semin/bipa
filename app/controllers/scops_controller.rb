class ScopsController < ApplicationController

  caches_page :show

  def index
    @scops = ScopDomain.rpall.paginate(:page => params[:page] || 1, :per_page => 20)

    respond_to do |format|
      format.html
    end
  end

  def show
    @scop = Scop.find(params[:id])
    @dna_subfamily = @scop.andand.nr80_dna_subfamily
    @rna_subfamily = @scop.andand.nr80_rna_subfamily
    @dna_subfamily_alignment = @dna_subfamily.andand.alignment
    @rna_subfamily_alignment = @rna_subfamily.andand.alignment
    @dna_nr_family_alignment = @scop.scop_family.andand.nr80_dna_alignment
    @rna_nr_family_alignment = @scop.scop_family.andand.nr80_rna_alignment

    if @scop.is_a? ScopDomain
      respond_to do |format|
        format.html
      end
    else
      redirect_to domains_scop_path(@scop)
    end
  end

  def domains
    @scop = Scop.find(params[:id])
    @doms = @scop.scop_domains.paginate(:page => params[:page] || 1, :per_page => 20)

    respond_to do |format|
      format.html
    end
  end

  def search
    @query = params[:query]
    @scops = ScopDomain.rpall.search(@query, :match_mode => :extended, :page => params[:page], :per_page => 10).compact

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

  def jmol
    @scop = Scop.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

end
