class Dssp < ActiveRecord::Base

  set_table_name "dssp"

  belongs_to :residue,
             :class_name  => "AaResidue",
             :foreign_key => "residue_id"
end
