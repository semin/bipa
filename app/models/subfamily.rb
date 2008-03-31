class Subfamily < ActiveRecord::Base

  belongs_to  :scop_family,
              :class_name   => "ScopFamily",
              :foreign_key  => "scop_family_id"

  has_one :alignment,
          :class_name   => "Alignment",
          :foreign_key  => "subfamily_id"

  has_many  :scop_domains,
            :class_name   => "ScopDomains",
            :foreign_key  => "subfamily_id"

  def representative
    rep = nil
    scop_domains.each do |domain|
      next if domain.calpha_only?
      if domain.resolution
        if rep && rep.resolution
          rep = domain if domain.resolution < rep.resolution
        else
          rep = domain
        end
      else
        rep = domain if rep.nil?
      end
    end
    rep
  end
end

(10..100).step(10) do |si|
  eval <<-EVAL
    class Subfamily#{si} < Subfamily

      has_many  :scop_domains,
                :class_name   => "ScopDomains",
                :foreign_key  => "subfamily#{si}_id"
    end
  EVAL
end

