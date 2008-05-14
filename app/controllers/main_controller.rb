class MainController < ApplicationController

  def home
    @scop_tree = Scop.root.ul_tree

    respond_to do |format|
      format.html
    end
  end

  def contact
    respond_to do |format|
      format.html
    end
  end
end
