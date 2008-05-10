class GoaPdb < ActiveRecord::Base

  belongs_to :chain

  belongs_to :go_term
end
