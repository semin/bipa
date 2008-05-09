class GoRelationship < ActiveRecord::Base
end


class GoPartOf < GoRelationship

  belongs_to  :part,
              :class_name   => "GoTerm",
              :foreign_key  => :subject_id

  belongs_to  :whole,
              :class_name   => "GoTerm",
              :foreign_key  => :object_id
end


class GoRegulate < GoRelationship

  belongs_to  :regulator,
              :class_name   => "GoTerm",
              :foreign_key  => :subject_id

  belongs_to  :regulatee,
              :class_name   => "GoTerm",
              :foreign_key  => :object_id
end


class GoPositivelyRegulate < GoRegulate
end


class GoNegativelyRegulate < GoRegulate
end
