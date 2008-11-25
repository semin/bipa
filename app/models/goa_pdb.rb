class GoaPdb < ActiveRecord::Base

  cattr_reader :version

  @@version = "14 Oct 2008"

  belongs_to :chain

  belongs_to :go_term
end
