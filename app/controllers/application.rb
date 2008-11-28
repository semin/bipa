# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

# STI dependency
require_dependency "scop"
require_dependency "atom"
require_dependency "chain"
require_dependency "residue"
require_dependency "interface"
require_dependency "subfamily"
require_dependency "alignment"
require_dependency "go_relationship"
require_dependency "gloria"
require_dependency "mmcif"
require_dependency "esst"
require_dependency "fugue_hit"
require_dependency "fugue_search"
require_dependency "test_alignment"

class ApplicationController < ActionController::Base

  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  # protect_from_forgery :secret => 'e261122355986ef81c09856e3e6bb836'

  # Semin: disable forgery protection
  self.allow_forgery_protection = false

#  def set_redundancy_and_resolution
#    session[:redundancy] = params[:redundancy]
#    session[:resolution] = params[:resolution]
#
#    flash[:notice] = "Maximum seqeunce identity has been set to #{session[:redundancy]}"
#    flash[:notice] += " %" if session[:redundancy].to_i > 0
#    flash[:notice] += "<br/>" if flash[:notice]
#    flash[:notice] += "Maximum resolution has been set to #{session[:resolution]}"
#    flash[:notice] += " &Aring" if session[:resolution].to_f > 0.0
#
#    redirect_to :back
#  end
#
#  def set_per_page
#    session[:per_page] = params[:per_page]
#    flash[:notice] = "Entries per page has been set to #{params[:per_page]}"
#    redirect_to :back
#  end


  private

  def local_request?
    false
  end

end
