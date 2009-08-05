class Subfamily < ActiveRecord::Base

  belongs_to  :family,
              :class_name   => "ScopFamily",
              :foreign_key  => "scop_id"

  has_one :alignment,
          :class_name   => "SubfamilyAlignment",
          :foreign_key  => "subfamily_id"

end


%w[dna rna].each do |na|
  eval <<-EVAL
  class #{na.capitalize}BindingSubfamily < Subfamily

    has_many  :domains,
              :class_name   => "ScopDomain",
              :foreign_key  => "#{na}_binding_subfamily_id"

    def representative
      domains.select { |d| d.rep_#{na} }.first
    end

    def calculate_representative
      rep = nil
      domains.each do |domain|
        if !domain.calpha_only? and !domain.has_unks?
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
      end
      rep
    end
  end
  EVAL
end
