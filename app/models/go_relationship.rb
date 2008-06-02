class GoRelationship < ActiveRecord::Base

  belongs_to  :source,
              :class_name   => "GoTerm",
              :foreign_key  => :source_id

  belongs_to  :target,
              :class_name   => "GoTerm",
              :foreign_key  => :target_id

end


class GoIsA < GoRelationship

  belongs_to  :subclass,
              :class_name   => "GoTerm",
              :foreign_key  => :source_id

  belongs_to  :superclass,
              :class_name   => "GoTerm",
              :foreign_key  => :target_id

end


class GoPartOf < GoRelationship

  belongs_to  :part,
              :class_name   => "GoTerm",
              :foreign_key  => :source_id

  belongs_to  :whole,
              :class_name   => "GoTerm",
              :foreign_key  => :target_id

end


class GoRegulates < GoRelationship

  belongs_to  :regulator,
              :class_name   => "GoTerm",
              :foreign_key  => :source_id

  belongs_to  :regulatee,
              :class_name   => "GoTerm",
              :foreign_key  => :target_id

end


class GoPositivelyRegulates < GoRelationship

  belongs_to  :positive_regulator,
              :class_name   => "GoTerm",
              :foreign_key  => :source_id

  belongs_to  :positive_regulatee,
              :class_name   => "GoTerm",
              :foreign_key  => :target_id

end


class GoNegativelyRegulates < GoRelationship

  belongs_to  :negative_regulator,
              :class_name   => "GoTerm",
              :foreign_key  => :source_id

  belongs_to  :negative_regulatee,
              :class_name   => "GoTerm",
              :foreign_key  => :target_id

end
