class Contact < ActiveRecord::Base

  belongs_to  :atom,
              :class_name     => 'Atom',
              :foreign_key    => 'atom_id',
              :counter_cache  => "contacts_count"

  belongs_to  :contacting_atom,
              :class_name     => 'Atom',
              :foreign_key    => 'contacting_atom_id',
              :counter_cache  => "contacts_count"
end
