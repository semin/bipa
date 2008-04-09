class Column < ActiveRecord::Base

  belongs_to :alignment

  belongs_to :residue
end
