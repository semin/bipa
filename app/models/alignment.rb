class Alignment < ActiveRecord::Base

  has_many :sequences
end


class FullAlignment < Alignment

  belongs_to  :family,
              :class_name   => "ScopFamily",
              :foreign_key  => "scop_family_id"
end


class SubfamilyAlignment < Alignment

  belongs_to  :subfamily,
              :class_name   => "SubFamily",
              :foreign_key  => "subfamily_id"
end


(10..100).step(10) do |si|
  eval <<-EVAL
    class Rep#{si}Alignment < Alignment

      belongs_to  :family,
                  :class_name   => "ScopFamily",
                  :foreign_key  => "scop_family_id"
    end
  EVAL
end
