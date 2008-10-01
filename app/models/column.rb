class Column < ActiveRecord::Base

  belongs_to :alignment

  has_many  :positions

  has_many  :profile_columns

end
