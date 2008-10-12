class VdwContact < ActiveRecord::Base

  include ImportWithLoadDataInFile

  belongs_to  :atom,
              :class_name     => 'Atom',
              :foreign_key    => 'atom_id',
              :counter_cache  => :vdw_contacts_count

  belongs_to  :vdw_contacting_atom,
              :class_name     => 'Atom',
              :foreign_key    => 'vdw_contacting_atom_id',
              :counter_cache  => :vdw_contacts_count
end
