class TaxonomicName < ActiveRecord::Base

  acts_as_ferret  :fields => [:name_txt, :unique_name, :name_class, :rank],
                  :store_classname => true,
                  :remote => true

  belongs_to  :node,
              :class_name   => "TaxonomicNode",
              :foreign_key  => "taxonomic_node_id"

  delegate :rank, :to => :node

end
