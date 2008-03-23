class Bipa::Chain < ActiveRecord::Base

  include Bipa::Usr
  include Bipa::ComposedOfResidues
  include Bipa::ComposedOfAtoms

  belongs_to  :model,
              :class_name   => "Bipa::Model",
              :foreign_key  => "model_id"

  has_many  :residues,
            :class_name => "Bipa::Residue"
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

end # class Bipa::Chain


class Bipa::AaChain < Bipa::Chain

  include Bipa::NucleicAcidBinding

  has_many  :dna_interfaces,
            :class_name   => 'Bipa::ChainDnaInterface',
            :foreign_key  => 'chain_id'

  has_many  :rna_interfaces,
            :class_name   => 'Bipa::ChainRnaInterface',
            :foreign_key  => 'chain_id'

  has_many  :domains,
            :through      => :residues,
            :uniq         => true

end


class Bipa::NaChain < Bipa::Chain
end


class Bipa::DnaChain < Bipa::NaChain
end


class Bipa::RnaChain < Bipa::NaChain
end


class Bipa::HnaChain < Bipa::NaChain

  has_many  :dna_residues,
            :class_name => "Bipa::DnaResidue",

  has_many  :rna_residues
            :class_name => "Bipa::RnaResidue"

  has_many  :dna_atoms,
            :through  => :dna_residues,
            :source   => :atoms

  has_many  :rna_atoms,
            :through  => :rna_residues,
            :source   => :atoms

end


class Bipa::HetChain < Bipa::Chain
end
