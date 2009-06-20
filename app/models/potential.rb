class Potential < ActiveRecord::Base

  include ImportWithLoadDataInFile

  belongs_to :atom

end
