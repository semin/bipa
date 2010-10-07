class TaxonomicNode < ActiveRecord::Base

  acts_as_tree

  has_many  :taxonomic_names

  has_one   :scientific_name,
            :class_name   => "TaxonomicName",
            :foreign_key  => "taxonomic_node_id",
            :conditions   => ["name_class = 'scientific name'"]

end
