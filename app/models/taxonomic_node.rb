class TaxonomicNode < ActiveRecord::Base

  has_many  :names,
            :class_name   => "TaxonomicName",
            :foreign_key  => "taxonomic_node_id"
end
