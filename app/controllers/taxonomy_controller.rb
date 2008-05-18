class TaxonomyController < ApplicationController

  def children
    respond_to do |format|
      format.json { render :json => "[]" }
    end
  end
end
