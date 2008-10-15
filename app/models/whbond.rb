class Whbond < ActiveRecord::Base

  include ImportWithLoadDataInFile

  belongs_to  :atom,
              :class_name     => "Atom",
              :foreign_key    => "atom_id"

  belongs_to  :whbonding_atom,
              :class_name     => "Atom",
              :foreign_key    => "whbonding_atom_id"

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
