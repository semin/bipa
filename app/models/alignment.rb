class Alignment < ActiveRecord::Base

  belongs_to  :family,
              :class_name   => "ScopFamily",
              :foreign_key  => "scop_family_id"

  has_many  :columns,
            :class_name   => "Column",
            :foreign_key  => "alignment_id"

end


(10..100).step(10) do |si|
  eval <<-EVAL
    class Alignment#{si} < Alignment

    end
  EVAL
end
