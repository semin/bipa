class Whbond < ActiveRecord::Base

  belongs_to  :aa_atom,
              :class_name   => "Atom",
              :foreign_key  => "aa_atom_id"

  belongs_to  :na_atom,
              :class_name   => "Atom",
              :foreign_key  => "na_atom_id"

  belongs_to  :water_atom,
              :class_name   => "Atom",
              :foreign_key  => "water_atom_id"

  belongs_to  :aa_water_hbond,
              :class_name   => "Hbplus",
              :foreign_key  => "aa_water_hbond_id"

  belongs_to  :na_water_hbond,
              :class_name   => "Hbplus",
              :foreign_key  => "na_water_hbond_id"
end
