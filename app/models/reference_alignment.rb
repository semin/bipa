class ReferenceAlignment < ActiveRecord::Base

  belongs_to  :alignment

  belongs_to  :template,
              :class_name   => "Scop",
              :foreign_key  => "template_id"

  belongs_to  :target,
              :class_name   => "Scop",
              :foreign_key  => "target_id"

  has_many :test_alignments

  has_one :test_needle_alignment

  has_one :test_clustalw_alignment

  has_one :test_std_fugue_alignment

  has_one :test_na_fugue_alignment

  named_scope :pid_range, lambda { |*args|
    { :conditions => ["pid#{args[0]} > ? and pid#{args[0]} <= ?", args[1], args[2]] }
  }

end
