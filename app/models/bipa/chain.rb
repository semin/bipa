class Bipa::Chain < ActiveRecord::Base

  include Bipa::Usr
  include Bipa::ComposedOfResidues
  include Bipa::ComposedOfAtoms

  belongs_to  :model,
              :class_name   => "Bipa::Model",
              :foreign_key  => "model_id"

  has_many  :residues,
            :class_name => "Bipa::Residue",
            :dependent  => :destroy
end


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
            :class_name   => "Bipa::DnaResidue",
            :foreign_key  => "chain_id"

  has_many  :rna_residues,
            :class_name   => "Bipa::RnaResidue",
            :foreign_key  => "chain_id"
end


class Bipa::HetChain < Bipa::Chain
end
