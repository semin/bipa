class Chain < ActiveRecord::Base
  
  include BIPA::USR
  include BIPA::NucleicAcidBinding
  include BIPA::ComposedOfResidues
  include BIPA::ComposedOfAtoms

  belongs_to :model
  
  has_many :dna_interfaces, :class_name => 'ChainDnaInterface', :foreign_key => 'chain_id'
  has_many :rna_interfaces, :class_name => 'ChainRnaInterface', :foreign_key => 'chain_id'
  
  has_many :residues, :dependent => :destroy
  has_many :std_residues
  has_many :aa_residues
  has_many :na_residues
  has_many :dna_residues
  has_many :rna_residues
  has_many :het_residues

  has_many :domains, :through => :aa_residues, :uniq => true
           
  has_many :atoms,     :through => :residues
  has_many :aa_atoms,  :through => :aa_residues,   :source => :atoms
  has_many :dna_atoms, :through => :dna_residues,  :source => :atoms
  has_many :rna_atoms, :through => :rna_residues,  :source => :atoms
  has_many :het_atoms, :through => :het_residues,  :source => :atoms
           
  has_many :contacts,         :through => :atoms
  has_many :contacting_atoms, :through => :contacts
    
  has_many :whbonds,          :through => :atoms
  has_many :whbonding_atoms,  :through => :whbonds
  
  has_many :hbonds_as_donor,    :through => :atoms
  has_many :hbonds_as_acceptor, :through => :atoms
  has_many :hbonding_donors,    :through => :hbonds_as_acceptor
  has_many :hbonding_acceptors, :through => :hbonds_as_donor
  
  lazy_calculate :unbound_asa, :bound_asa, :delta_asa

  def has_dna?
    dna_residues.size > 0
  end
  
  def has_rna?
    rna_residues.size > 0
  end
  
  def has_het?
    het_residues.size > 0
  end
  
  def had_aa?
    aa_residues.size > 0
  end
end # class Chain


class ProteinChain < Chain
end


class NucleicAcidChain < Chain
end


class DnaChain < NucleicAcidChain
end


class RnaChain < NucleicAcidChain
end


class HnaChain < NucleicAcidChain
end


class HetChain < Chain
end

