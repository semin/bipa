class Chain < ActiveRecord::Base

  include Bipa::ComposedOfResidues

  belongs_to  :model

  has_many  :residues,
            :dependent    => :destroy

  has_many  :aa_residues

  has_many  :na_residues

  has_many  :dna_residues

  has_many  :rna_residues

  has_many  :het_residues

  has_many  :atoms,
            :through      => :residues

  has_many  :aa_atoms,
            :through      => :aa_residues,
            :source       => :atoms

  has_many  :na_atoms,
            :through      => :na_residues,
            :source       => :atoms

  has_many  :dna_atoms,
            :through      => :dna_residues,
            :source       => :atoms

  has_many  :rna_atoms,
            :through      => :rna_residues,
            :source       => :atoms

  has_many  :het_atoms,
            :through      => :het_residues,
            :source       => :atoms

  has_many  :sequences

  validates_uniqueness_of :chain_code,
                          :scope          => :model_id,
                          :allow_nil      => true,
                          :case_sensitive => true

  def fasta_header
    "#{model.structure.pdb_code}:#{chain_code}"
  end
end


class AaChain < Chain

  has_many  :dna_interfaces,
            :class_name   => "ChainDnaInterface",
            :foreign_key  => "chain_id"

  has_many  :rna_interfaces,
            :class_name   => "ChainRnaInterface",
            :foreign_key  => "chain_id"

  has_many  :domains,
            :through      => :aa_residues,
            :uniq         => true
end


class NaChain < Chain
end


class DnaChain < NaChain
end


class RnaChain < NaChain
end


class HnaChain < NaChain
end


class PseudoChain < Chain
end
