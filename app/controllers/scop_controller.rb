class ScopController < ApplicationController

  def index
    order = case params[:sort]
            when "id"           then "id"
            when "stype"        then "stype"
            when "sunid"        then "sunid"
            when "sccs"         then "sccs"
            when "sid"          then "sid"
            when "description"  then "description"
            when "id_reverse"           then "id DESC"
            when "stype_reverse"        then "stype DESC"
            when "sunid_reverse"        then "sunid DESC"
            when "sccs_reverse"         then "sccs DESC"
            when "sid_reverse"          then "sid DESC"
            when "description_reverse"  then "description DESC"
            else; "id"
            end

    @scops = Scop.send("rep#{@redundancy}").paginate(
      :per_page => session[:per_page] || 10,
      :page => params[:page],
      :order => order
    )

    respond_to do |format|
      format.html
    end
  end

  def show
    @scop = Scop.find(params[:id])

    respond_to do |format|
      format.html { redirect_to summary_scop_url(@scop) }
    end
  end

  def search
    @query = params[:query]
    @hits = Scop.find_with_ferret(@query, :limit => :all)

    respond_to do |format|
      format.html
    end
  end

  def summary
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

  def frequencies
    @scop = Scop.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  def alignments
    @scop = Scop.find(params[:id])

    if @scop.level < 5
      @families = @scop.all_filtered_children(@redundancy).select { |c| c.level == 4 }
      @alignments = @families.map { |f| f.send("rep#{@redundancy}_alignment") }.compact
    else
      @alignments = nil
    end

    respond_to do |format|
      format.html
    end
  end

  def interfaces
    @scop = Scop.find(params[:id])
    @dna_interfaces = @scop.dna_interfaces(@redundancy, @resolution)
    @rna_interfaces = @scop.rna_interfaces(@redundancy, @resolution)
    @interfaces = @dna_interfaces + @rna_interfaces

    respond_to do |format|
      format.html
    end
  end

  def children
    root = params[:root]

    if root == "root"
      children = Scop.send("rep#{@redundancy}").find(1).filtered_children(@redundancy)
    else
      children = Scop.send("rep#{@redundancy}").find(root).filtered_children(@redundancy)
    end

    children.each do |child|
      child[:tree_title] = child.tree_title
      if child.filtered_children(@redundancy).size > 0
        child[:hasChildren] = true
      end
    end

    respond_to do |format|
      format.json { render :json => children.to_json }
    end
  end
end
