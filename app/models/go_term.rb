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

  has_many  :regulators,
            :through      => :relationships_as_regulatee

  has_many  :regulatees,
            :through      => :relationships_as_regulator

  # positively_regulates
  has_many  :relationships_as_positive_regulator,
            :class_name   => "GoPositivelyRegulates",
            :foreign_key  => "source_id"

  has_many  :relationships_as_positive_regulatee,
            :class_name   => "GoPositivelyRegulates",
            :foreign_key  => "target_id"

  has_many  :positive_regulators,
            :through      => :relationships_as_positive_regulatee

  has_many  :positive_regulatees,
            :through      => :relationships_as_positive_regulator

  # negatively_regulates
  has_many  :relationships_as_negative_regulator,
            :class_name   => "GoNegativelyRegulates",
            :foreign_key  => "source_id"

  has_many  :relationships_as_negative_regulatee,
            :class_name   => "GoNegativelyRegulates",
            :foreign_key  => "target_id"

  has_many  :negative_regulators,
            :through      => :relationships_as_negative_regulatee

  has_many  :negative_regulatees,
            :through      => :relationships_as_negative_regulator

  # etc
  has_many  :goa_pdbs

  has_many  :chains,
            :through      => :goa_pdbs
end

