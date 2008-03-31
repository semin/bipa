class Whbond < ActiveRecord::Base

  belongs_to  :atom,
              :foreign_key  => "atom_id"
              
  belongs_to  :whbonding_atom, 
              :class_name   => "Atom",
              :foreign_key  => "whbonding_atom_id"
              
  belongs_to  :water_atom,
              :class_name   => "Atom",
              :foreign_key  => "water_atom_id"
end