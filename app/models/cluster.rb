class Cluster < ActiveRecord::Base

  belongs_to :scop_family

  has_many :scop_domains

end

(10..100).step(10) do |id|
  eval <<-CLASS
    class Cluster#{id} < Cluster
      
      has_many  :scop_domains,
                :class_name => "ScopDomain",
                :foreign_key => "cluster#{id}_id"
    end
  CLASS
end

