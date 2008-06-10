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

class ApplicationController < ActionController::Base

  before_filter :update_settings
  before_filter :update_classification, :only => :search

  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  # protect_from_forgery :secret => 'e261122355986ef81c09856e3e6bb836'

  # Semin: disable forgery protection
  self.allow_forgery_protection = false

  private

  def local_request?
    false
  end

  def update_settings
    if params[:redundancy]
      @redundancy = (session[:redundancy] = params[:redundancy])
      flash[:notice] = "Maximum seqeunce identity has been set to #{@redundancy}"
      flash[:notice] += " %" if @redundancy.to_i > 0
    elsif session[:redundancy]
      @redundancy = session[:redundancy]
    else
      @redundancy = session[:redundancy] = "90"
    end

    if params[:resolution]
      @resolution = (session[:resolution] = params[:resolution].to_f)
      flash[:notice] += "<br/>" if flash[:notice]
      flash[:notice] += "Maximum resolution has been set to #{@resolution} &Aring"
    elsif session[:resolution]
      @resolution = session[:resolution]
    else
      @resolution = session[:resolution] = "3.5"
    end
  end

  def update_classification
    session[:classification] = params[:classification]
  end

end
