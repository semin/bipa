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

  named_scope :pid1_0_20,   :conditions => ["pid1 >= 0 and pid1 < 20"]
  named_scope :pid1_20_30,  :conditions => ["pid1 >= 20 and pid1 < 30"]
  named_scope :pid1_30_40,  :conditions => ["pid1 >= 30 and pid1 < 40"]
  named_scope :pid1_40_100, :conditions => ["pid1 >= 40 and pid1 <= 100"]

  named_scope :pid_range,   lambda { |*args|
    { :conditions => ["pid#{args[0]} > ? and pid#{args[0]} <= ?", args[1], args[2]] }
  }

end
