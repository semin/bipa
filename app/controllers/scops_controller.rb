class ScopsController < ApplicationController

  caches_page :show, :jmol

  def index
    @query = params[:query]

    if @query && !@query.empty?
      @scops = ScopDomain.reg_all.search(@query, :match_mode => :extended, :page => params[:page], :per_page => 10)
    else
      @scops = ScopDomain.reg_all.paginate(:page => params[:page] || 1, :per_page => 10)
    end

    respond_to do |format|
      format.html
    end
  end

  def show
    @scop = Scop.reg_all.find_by_sunid(params[:id])

    if @scop.is_a? ScopDomain

      @dna_subfamily = @scop.dna_binding_subfamily
      @rna_subfamily = @scop.rna_binding_subfamily

      @dna_subfamily_alignment = @dna_subfamily.andand.alignment
      @rna_subfamily_alignment = @rna_subfamily.andand.alignment

      @dna_family_alignment = @scop.scop_family.dna_binding_family_alignments.select { |a| a.contains?(@dna_subfamily.andand.representative) }[0]
      @rna_family_alignment = @scop.scop_family.rna_binding_family_alignments.select { |a| a.contains?(@rna_subfamily.andand.representative) }[0]

      respond_to do |format|
        format.html
      end
    else
      redirect_to domains_scop_url(@scop)
    end
  end

  def domains
    @scop = Scop.find_by_sunid(params[:id])
    @doms = @scop.scop_domains.paginate(:page => params[:page] || 1, :per_page => 20)

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
