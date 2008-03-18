class Cluster < ActiveRecord::Base

  belongs_to :scop_family

  has_many :scop_domains

  def representative
    rep = nil
    scop_domains.each do |domain|
      if rep.nil?
        rep = domain
      else
        rep = domain if domain.resolution < rep.resolution
      end
    end
    rep
  end

end

(10..100).step(10) do |i|
  eval <<-CLASS
    class Cluster#{i} < Cluster

      has_many :scop_domains

    end
  CLASS
end

