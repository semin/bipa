class GoAssociation < ActiveRecord::Base

  belongs_to  :subclass,
              :class_name   => "GoTerm",
              :foreign_key  => "subclass_id"

  belongs_to  :superclass,
              :class_name   => "GoTerm",
              :foreign_key  => "superclass_id"
end
