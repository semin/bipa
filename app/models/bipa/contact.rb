class Contact < ActiveRecord::Base

  belongs_to :atom,            :class_name => 'Atom', :foreign_key  => 'atom_id'
  belongs_to :contacting_atom, :class_name => 'Atom', :foreign_key  => 'contacting_atom_id'

end
