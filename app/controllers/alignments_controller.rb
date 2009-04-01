class AlignmentsController < ApplicationController

  caches_page :jalview

  def jalview
    @alignment = Alignment.find(params[:id])

    respond_to do |format|
      format.html
    end
  end
end
