class GoRelationship < ActiveRecord::Base
end


class GoPartOf < GoRelationship

  belongs_to  :part,
              :class_name   => "GoTerm",
              :foreign_key  => "go_term_id"

  belongs_to  :whole,
              :class_name   => "GoTerm",
              :foreign_key  => "related_go_term_id"
end


class GoRegulate < GoRelationship
end


class GoPositivelyRegulate < GoRelationship
end


class GoNegativelyRegulate < GoRelationship
end
