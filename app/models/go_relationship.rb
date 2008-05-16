class GoRelationship < ActiveRecord::Base
end


class GoIsA < GoRelationship

  belongs_to  :subclass,
              :class_name   => "GoTerms",
              :foreign_key  => :source_id

  belongs_to  :superclass,
              :class_name   => "GoTerms",
              :foreign_key  => :target_id
end


class GoPartOf < GoRelationship

  belongs_to  :part,
              :class_name   => "GoTerms",
              :foreign_key  => :source_id

  belongs_to  :whole,
              :class_name   => "GoTerms",
              :foreign_key  => :target_id
end


class GoRegulate < GoRelationship

  belongs_to  :regulator,
              :class_name   => "GoTerms",
              :foreign_key  => :source_id

  belongs_to  :regulatee,
              :class_name   => "GoTerms",
              :foreign_key  => :target_id
end


class GoPositivelyRegulate < GoRegulate
end


class GoNegativelyRegulate < GoRegulate
end
