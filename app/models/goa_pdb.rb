class GoaPdb < ActiveRecord::Base

  belongs_to :structure

  belongs_to :go_term
end
