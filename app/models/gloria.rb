class Gloria < ActiveRecord::Base

  self.abstract_class = true
  establish_connection "GLORIA"

end


#class ResMap < Gloria
#
#  set_table_name "ResMap"
#  set_primary_key "res_id"
#
#  has_one :residue,
#          :class_name   => "Residue",
#          :foreign_key  => "res_map_id"
#end
#
#
#class ResidueMap < Gloria
#
#  set_table_name "ResidueMap"
#  set_primary_key "res_id"
#
#  has_one :residue,
#          :class_name   => "Residue",
#          :foreign_key  => "residue_map_id"
#
#end
