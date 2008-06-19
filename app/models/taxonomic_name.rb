class TaxonomicName < ActiveRecord::Base

  belongs_to  :node,
              :class_name   => "TaxonomicNode",
              :foreign_key  => "taxonomic_node_id"

  delegate :rank, :to => :node

  define_index do
    indexes name_txt,     :sortable => true
    indexes unique_name,  :sortable => true
    indexes name_class,   :sortable => true
    indexes node.rank,    :sortable => true, :as => :rank
  end

end
