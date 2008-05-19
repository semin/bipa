class TaxonomicNode < ActiveRecord::Base

  acts_as_tree

  has_many  :names,
            :class_name   => "TaxonomicName",
            :foreign_key  => "taxonomic_node_id"
end
