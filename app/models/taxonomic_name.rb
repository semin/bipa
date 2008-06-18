class TaxonomicName < ActiveRecord::Base

  belongs_to  :node,
              :class_name   => "TaxonomicNode",
              :foreign_key  => "taxonomic_node_id"

  delegate :rank, :to => :node

#  acts_as_ferret  :fields => [ :name_txt, :unique_name, :name_class, :rank ],
#                  :remote => true

end
