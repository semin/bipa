class ScopsController < ApplicationController

  caches_page :show, :jmol

  def index
    @scops = ScopDomain.reg_all.paginate(:page => params[:page] || 1, :per_page => 20)

    respond_to do |format|
      format.html
    end
  end

  def show
    @scop = Scop.find(params[:id])

    if @scop.is_a? ScopDomain
      @dna_subfamily = @scop.andand.red_dna_binding_subfamily
      @rna_subfamily = @scop.andand.red_rna_binding_subfamily
      @dna_subfamily_alignment = @dna_subfamily.andand.alignment
      @rna_subfamily_alignment = @rna_subfamily.andand.alignment
      @dna_rep_family_alignments = @scop.scop_family.andand.rep_dna_binding_family_alignments
      @rna_rep_family_alignments = @scop.scop_family.andand.rep_rna_binding_family_alignments

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
    @scops = ScopDomain.reg_all.search(@query,
                                          :match_mode => :extended,
                                          :page => params[:page],
                                          :per_page => 10).compact

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
