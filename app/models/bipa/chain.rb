class Chain < ActiveRecord::Base

  include BIPA::USR
  include BIPA::ComposedOfResidues
  include BIPA::ComposedOfAtoms

  belongs_to :model

  has_many  :residues,
            :dependent  => :destroy

  has_many  :atoms,
            :through    => :residues

  has_many  :contacts,
            :through    => :atoms

  has_many  :contacting_atoms,
            :through    => :contacts

  has_many  :whbonds,
            :through    => :atoms

  has_many  :whbonding_atoms,
            :through    => :whbonds

  has_many  :hbonds_as_donor,
            :through    => :atoms

  has_many  :hbonds_as_acceptor,
            :through    => :atoms

  has_many  :hbonding_donors,
            :through    => :hbonds_as_acceptor

  has_many  :hbonding_acceptors,
            :through    => :hbonds_as_donor

end # class Chain


class AaChain < Chain

  include BIPA::NucleicAcidBinding

  has_many  :dna_interfaces,
            :class_name   => 'ChainDnaInterface',
            :foreign_key  => 'chain_id'

  has_many  :rna_interfaces,
            :class_name   => 'ChainRnaInterface',
            :foreign_key  => 'chain_id'

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

  has_many  :dna_residues
  has_many  :rna_residues

  has_many  :dna_atoms,
            :through  => :dna_residues,
            :source   => :atoms

  has_many  :rna_atoms,
            :through  => :rna_residues,
            :source   => :atoms

end


class HetChain < Chain
end