# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

## STI dependency
#require_dependency "scop"
#require_dependency "atom"
#require_dependency "chain"
#require_dependency "residue"
#require_dependency "interface"
#require_dependency "subfamily"
#require_dependency "alignment"
#require_dependency "go_relationship"
#require_dependency "gloria"
#require_dependency "mmcif"
#require_dependency "requiem"
#require_dependency "esst"
#require_dependency "fugue_hit"
#require_dependency "fugue_search"
#require_dependency "test_alignment"
#
class ApplicationController < ActionController::Base

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

end
