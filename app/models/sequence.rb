class Sequence < ActiveRecord::Base

  belongs_to  :alignment

  belongs_to  :domain,
              :class_name => "ScopDomain",
              :foreign_key  => "scop_domain_id"

  belongs_to  :chain

  has_many :columns
end
