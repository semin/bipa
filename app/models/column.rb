class Column < ActiveRecord::Base

  belongs_to :alignment

  has_many  :positions
end
