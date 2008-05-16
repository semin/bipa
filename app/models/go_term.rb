class GoTerm < ActiveRecord::Base

  has_many  :associations_as_subclass,
            :class_name   => "GoAssociation",
            :foreign_key  => "subclass_id"

  has_many  :associations_as_superclass,
            :class_name   => "GoAssociation",
            :foreign_key  => "superclass_id"

  has_many  :subclasses,
            :through      => :associations_as_subclass

  has_many  :superclasses,
            :through      => :associations_as_superclass

  has_many  :goa_pdbs

  has_many  :chains,
            :through      => :goa_pdbs
end
