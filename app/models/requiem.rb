class Requiem < ActiveRecord::Base

  self.abstract_class = true
  establish_connection "REQUIEM"

end


class Variation2PDB < Requiem

  set_table_name :Variation2PDB

  belongs_to  :variation,
              :class_name => "Variation",
              :foreign_key => :variation_id


end


class Variation < Requiem

  set_table_name :Variations

  has_many  :variation2_pdbs,
            :class_name => "Variation2PDB",
            :foreign_key => :variation_id

end

