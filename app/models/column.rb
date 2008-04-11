class Column < ActiveRecord::Base

  belongs_to :sequence

  belongs_to :residue
end
