class GoTerm < ActiveRecord::Base

  # is_a
  has_many  :relationships_as_subclass,
            :class_name   => "GoIsA",
            :foreign_key  => "source_id"

  has_many  :relationships_as_superclass,
            :class_name   => "GoIsA",
            :foreign_key  => "target_id"

  has_many  :subclasses,
            :through      => :relationships_as_superclass

  has_many  :superclasses,
            :through      => :relationships_as_subclass

  # part_of
  has_many  :relationships_as_part,
            :class_name   => "GoPartOf",
            :foreign_key  => "source_id"

  has_many  :relationships_as_whole,
            :class_name   => "GoPartOf",
            :foreign_key  => "target_id"

  has_many  :parts,
            :through      => :relationships_as_whole

  has_many  :wholes,
            :through      => :relationships_as_part

  # regulates
  has_many  :relationships_as_regulator,
            :class_name   => "GoRegulates",
            :foreign_key  => "source_id"

  has_many  :relationships_as_regulatee,
            :class_name   => "GoRegulates",
            :foreign_key  => "target_id"

  has_many  :regulator,
            :through      => :relationships_as_regulatee

  has_many  :regulatee,
            :through      => :relationships_as_regulator

  has_many  :goa_pdbs

  has_many  :chains,
            :through      => :goa_pdbs
end
