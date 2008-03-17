class Cluster < ActiveRecord::Base

  belongs_to :scop_family

  has_many  :scop_domains

end

