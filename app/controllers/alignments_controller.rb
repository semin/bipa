class AlignmentsController < ApplicationController

  before_filter :find_scop, :only => [:index, :show]

  def index
    if @scop.level < 5
      @families = @scop.descendants.send("res#{session[:resolution]}").select { |d| d.level == 4 }
      if session[:redundancy] == "all"
        @alignments = @families.map { |f| f.send("full_alignment") }.compact
      else
        @alignments = @families.map { |f| f.send("rep#{session[:redundancy]}_alignment") }.compact
      end
    else
      @alignments = nil
    end

    respond_to do |format|
      format.html
    end
  end

  def show
    @alignment = Alignment.find(params[:id])

    respond_to do |format|
      format.html
    end
  end


  private

  def find_scop
    @scop_id = params[:scop_id]

    redirect_to :back unless @scop_id
    @scop = Scop.find(@scop_id)
  end
end
