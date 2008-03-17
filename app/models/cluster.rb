class Cluster < ActiveRecord::Base

  belongs_to :scop_family

  has_many :scop_domains

end

(10..100).step(10) { |i| eval "class Cluster#{i} < Cluster; end" }

