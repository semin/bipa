class ResMap < Gloria

  set_table_name "ResMap"
  set_primary_key = "res_id"

  has_one :residue,
          :class_name   => "AaResidue",
          :foreign_key  => "res_map_id"
end
