class VdwContact < ActiveRecord::Base

  belongs_to  :atom,
              :class_name     => 'Atom',
              :foreign_key    => 'atom_id'

  belongs_to  :vdw_contacting_atom,
              :class_name     => 'Atom',
              :foreign_key    => 'vdw_contacting_atom_id'
end
