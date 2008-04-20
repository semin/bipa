class Position < ActiveRecord::Base

  belongs_to :sequence

  belongs_to :column

  belongs_to :residue
end
