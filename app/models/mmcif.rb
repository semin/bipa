class Mmcif < ActiveRecord::Base

  self.abstract_class = true
  establish_connection "MMCIF"

end

class Exptl < Mmcif

  set_primary_keys :Structure, :entry_id

end
class Citation < Mmcif

  set_primary_keys :Structure_ID, :id

end
class Refine < Mmcif

  set_primary_keys :Structure_ID, :entry_id

end
