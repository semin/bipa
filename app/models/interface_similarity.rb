class InterfaceSimilarity < ActiveRecord::Base

  belongs_to  :interface,
              :class_name   => "Interface",
              :foreign_key  => "interface_id"

  belongs_to  :interface_target,
              :class_name   => "Interface",
              :foreign_key  => "similar_interface_id"

end
