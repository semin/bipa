class Gloria::Base < ActiveRecord::Base

  self.abstract_class = true
  establish_connection "GLORIA"

end