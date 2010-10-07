class Subfamily < ActiveRecord::Base

  has_one :alignment,
          :class_name   => "SubfamilyAlignment",
          :foreign_key  => "subfamily_id"

end


class NaBindingScopSubfamily < Subfamily

  belongs_to  :family,
              :class_name   => "ScopFamily",
              :foreign_key  => "scop_id"


  def calculate_representative
    rep = nil
    domains.each do |domain|
      if !domain.calpha_only? && !domain.has_unks?
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


class DnaBindingScopSubfamily < NaBindingScopSubfamily

  has_many  :domains,
            :class_name   => "ScopDomain",
            :foreign_key  => "dna_binding_scop_subfamily_id"

  def representative
    domains.select { |d| d.rep_dna }.first
  end

end


class RnaBindingScopSubfamily < NaBindingScopSubfamily

  has_many  :domains,
            :class_name   => "ScopDomain",
            :foreign_key  => "rna_binding_scop_subfamily_id"

  def representative
    domains.select { |d| d.rep_rna }.first
  end

end


class NaBindingChainSubfamily < Subfamily

  belongs_to :tmalign_family

  def calculate_representative
    rep = nil
    chains.each do |chain|
      if !chain.calpha_only? && !chain.has_unks?
        if chain.resolution
          if rep && rep.resolution
            rep = chain if chain.resolution < rep.resolution
          else
            rep = chain
          end
        else
          rep = chain if rep.nil?
        end
      end
    end
    rep
  end

end


class DnaBindingChainSubfamily < NaBindingChainSubfamily

  has_many  :chains,
            :class_name   => "AaChain",
            :foreign_key  => "dna_binding_chain_subfamily_id"

  def representative
    chains.select { |d| d.rep_dna }.first
  end

end


class RnaBindingChainSubfamily < NaBindingChainSubfamily

  has_many  :chains,
            :class_name   => "AaChain",
            :foreign_key  => "rna_binding_chain_subfamily_id"

  def representative
    chains.select { |d| d.rep_rna }.first
  end

end
