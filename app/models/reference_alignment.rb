class ReferenceAlignment < ActiveRecord::Base

  belongs_to  :alingment

  belongs_to  :template,
              :class_name   => "Scop",
              :foreign_key  => "template_id"

  belongs_to  :target,
              :class_name   => "Scop",
              :foreign_key  => "target_id"

  has_many :test_alignments

end
