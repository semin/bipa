class Column < ActiveRecord::Base

  belongs_to  :alignment,
              :class_name   => "Alignment",
              :foreign_key  => "alignment_id"

  belongs_to :residue
end
