class Naccess < ActiveRecord::Base

  include ImportWithLoadDataInFile

  set_table_name "naccess"

  belongs_to :atom

end
