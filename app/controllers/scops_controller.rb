class ScopsController < ApplicationController

  caches_page :index, :show, :jmol

  def index
    @scops = ScopDomain.reg_all.paginate(:page => params[:page] || 1, :per_page => 20)

    respond_to do |format|
      format.html
    end
  end

  def show
    @scop = ScopDomain.find_by_sunid(params[:id])

    @dna_subfamily = @scop.dna_binding_subfamily
    @rna_subfamily = @scop.rna_binding_subfamily

    @dna_subfamily_alignment = @dna_subfamily.andand.alignment
    @rna_subfamily_alignment = @rna_subfamily.andand.alignment

    @dna_family_alignment = @scop.scop_family.dna_binding_family_alignments.
                            select { |a| a.contains?(@dna_subfamily.andand.representative) }[0]
    @rna_family_alignment = @scop.scop_family.rna_binding_family_alignments.
                            select { |a| a.contains?(@rna_subfamily.andand.representative) }[0]

    respond_to do |format|
      format.html
    end
  end

  def domains
    @scop = Scop.find_by_sunid(params[:id])
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

  def jmol
    @scop = ScopDomain.find_by_sunid(params[:id])

    respond_to do |format|
      format.html
    end
  end

end
