class GoaPdb < ActiveRecord::Base

  belongs_to :chain

  belongs_to :go
end
