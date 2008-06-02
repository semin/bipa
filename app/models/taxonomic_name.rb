class TaxonomicName < ActiveRecord::Base

  belongs_to  :node,
              :class_name   => "TaxonomicNode",
              :foreign_key  => "taxonomic_node_id"

  delegate :rank, :to => :node

end
