class Dssp < ActiveRecord::Base

  belongs_to :residue,
             :class_name  => "AaResidue",
             :foreign_key => "residue_id"
end
