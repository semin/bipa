class Subfamily < ActiveRecord::Base

  belongs_to  :family,
              :class_name   => "ScopFamily",
              :foreign_key  => "scop_id"

  has_one :alignment,
          :class_name   => :SubfamilyAlignment,
          :foreign_key  => :subfamily_id

  has_many  :domains,
            :class_name   => :ScopDomain

  def representative
    rep = nil
    domains.each do |domain|
      next if domain.calpha_only? || domain.has_unks?
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


%w[dna rna].each do |na|
  eval <<-EVAL
    class #{na.capitalize}BindingSubfamily < Subfamily
    end
  EVAL
end
