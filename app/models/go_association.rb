class GoAssociation < ActiveRecord::Base

  belongs_to  :subclass,
              :class_name   => "Go",
              :foreign_key  => "subclass_id"

  belongs_to  :superclass,
              :class_name   => "Go",
              :foreign_key  => "superclass_id"
end
