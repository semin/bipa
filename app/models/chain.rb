class Chain < ActiveRecord::Base

  include Bipa::ComposedOfResidues
  include Bipa::ComposedOfAtoms

  belongs_to  :model

  has_many  :residues,
            :class_name   => "Residue",
            :foreign_key  => "chain_id",
            :dependent    => :destroy

  has_many  :atoms,
            :through      => :residues

  has_many  :contacts,
            :through      => :atoms

  has_many  :contacting_atoms,
            :through      => :contacts

  has_many  :whbonds,
            :through      => :atoms

  has_many  :whbonding_atoms,
            :through      => :whbonds

  has_many  :hbonds_as_donor,
            :through      => :atoms

  has_many  :hbonds_as_acceptor,
            :through      => :atoms

  has_many  :hbonding_donors,
            :through      => :hbonds_as_acceptor

  has_many  :hbonding_acceptors,
            :through      => :hbonds_as_donor
end


class AaChain < Chain

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

  has_many  :dna_atoms,
            :through      => :dna_residues,
            :source       => :atoms

  has_many  :rna_atoms,
            :through      => :rna_residues,
            :source       => :atoms
end


class HetChain < Chain
end
