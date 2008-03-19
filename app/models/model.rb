class Model < ActiveRecord::Base

  include BIPA::USR
  include BIPA::NucleicAcidBinding
  include BIPA::ComposedOfResidues
  include BIPA::ComposedOfAtoms

  belongs_to :structure

  has_many :chains, :dependent => :delete_all

  has_many :domains, :through => :chains, :uniq => true

  has_many :residues,     :through => :chains
  has_many :std_residues, :through => :chains
  has_many :aa_residues,  :through => :chains
  has_many :na_residues,  :through => :chains
  has_many :dna_residues, :through => :chains
  has_many :rna_residues, :through => :chains
  has_many :het_residues, :through => :chains

  has_many :atoms,     :through => :residues
  has_many :aa_atoms,  :through => :aa_residues,  :source => :atoms
  has_many :dna_atoms, :through => :dna_residues, :source => :atoms
  has_many :rna_atoms, :through => :rna_residues, :source => :atoms
  has_many :het_atoms, :through => :het_residues, :source => :atoms

  has_many :contacts,           :through => :atoms
  has_many :contacting_atoms,   :through => :contacts

  has_many :whbonds,            :through => :atoms
  has_many :whbonding_atoms,    :through => :whbonds

  has_many :hbonds_as_donor,    :through => :atoms
  has_many :hbonds_as_acceptor, :through => :atoms
  has_many :hbonding_donors,    :through => :hbonds_as_acceptor
  has_many :hbonding_acceptors, :through => :hbonds_as_donor

  before_save :update_unbound_asa,
              :update_bound_asa,
              :update_delta_asa

  def chains_with_na
    chains.select { |c| c.has_na? }
  end

  def chains_with_dna
    chains.select { |c| c.has_dna? }
  end

  def chains_with_rna
    chains.select { |c| c.has_rna? }
  end

  # Callbacks
  def update_unbound_asa
    self.unbound_asa = atoms.inject(0) { |s, a| a.unbound_asa ? s + a.unbound_asa : s }
  end

  def update_bound_asa
    self.bound_asa = atoms.inject(0) { |s, a| a.bound_asa ? s + a.bound_asa : s }
  end

  def update_delta_asa
    self.delta_asa = atoms.inject(0) { |s, a| a.delta_asa ? s + a.delta_asa : s }
  end

end
