class Mmcif::Base < ActiveRecord::Base

  self.abstract_class = true
  establish_connection "MMCIF"

end

