class Cluster < ActiveRecord::Base

  belongs_to :scop_family

  has_one :alignment

  has_many :scop_domains

  def representative
    rep = nil
    scop_domains.each do |domain|
      if rep.nil?
        rep = domain
      else
        if not domain.resolution.nil?
          next if domain.calpha_only?
          if rep.resolution.nil?
            rep = domain
          else
            if domain.resolution < rep.resolution
              rep = domain
            end
          end
        end
      end
    end
    rep.calpha_only? ? nil : rep
  end

end

(10..100).step(10) do |i|
  eval <<-CLASS
    class Cluster#{i} < Cluster

      has_many :scop_domains

    end
  CLASS
end

