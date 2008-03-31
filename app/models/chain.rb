class Chain < ActiveRecord::Base

  include Bipa::Usr
  include Bipa::ComposedOfResidues
  include Bipa::ComposedOfAtoms

  belongs_to  :model

  has_many  :residues,
            :dependent    => :destroy

  def atoms
    residues.inject([]) { |s, r| s.concat(r.atoms) }
  end
end


class AaChain < Bipa::Chain

  include Bipa::NucleicAcidBinding

  has_many  :dna_interfaces,
            :class_name   => "ChainDnaInterface",
            :foreign_key  => "chain_id"

  has_many  :rna_interfaces,
            :class_name   => "ChainRnaInterface",
            :foreign_key  => "chain_id"

  has_many  :domains,
            :through      => :residues,
            :uniq         => true
end


class NaChain < Chain
end


class DnaChain < NaChain
end


class RnaChain < NaChain
end


class HnaChain < NaChain

  has_many  :dna_residues,
            :class_name   => "DnaResidue",
            :foreign_key  => "chain_id"

  has_many  :rna_residues,
            :class_name   => "RnaResidue",
            :foreign_key  => "chain_id"

  def dna_atoms
    dna_residues.inject([]) { |s, r| s.concat(r.atoms) }
  end

  def rna_atoms
    rna_residues.inject([]) { |s, r| s.concat(r.atoms) }
  end
end


class Bipa::HetChain < Bipa::Chain
end
