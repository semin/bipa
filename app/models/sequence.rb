class Sequence < ActiveRecord::Base

  belongs_to  :alignment

  belongs_to  :domain,
              :class_name => "ScopDomain",
              :foreign_key  => "scop_id"

  belongs_to  :chain

  has_many  :positions,
            :order  => "number"

end
