class Structure < ActiveRecord::Base

  include Bipa::ComposedOfResidues

  has_finder :untainted, :conditions => { :tainted => false }

  has_many  :models,
            :dependent  => :destroy

  has_many  :chains,
            :through    => :models

  has_many  :aa_chains,
            :through    => :models

  has_many  :na_chains,
            :through    => :models

  has_many  :dna_chains,
            :through    => :models

  has_many  :rna_chains,
            :through    => :models

  has_many  :hna_chains,
            :through    => :models

  has_many  :het_chains,
            :through    => :models

  def residues
    chains.inject([]) { |s, c| s.concat(c.residues) }
  end
  memoize :residues

  # has_many  :residues,
  #           :through    => :chains
  #
  # has_many  :aa_residues,
  #           :through    => :aa_chains,
  #           :source     => :residues
  #
  # has_many  :na_residues,
  #           :through    => :na_chains,
  #           :source     => :residues
  #
  # has_many  :dna_residues,
  #           :through    => :dna_chains,
  #           :source     => :residues
  #
  # has_many  :rna_residues,
  #           :through    => :rna_chains,
  #           :source     => :residues
  #
  # has_many  :hna_residues,
  #           :through    => :hna_chains,
  #           :source     => :residues
  #
  # has_many  :het_residues,
  #           :through    => :het_chains,
  #           :source     => :residues
  #
  # has_many  :atoms,
  #           :through    => :residues
  #
  # has_many  :aa_atoms,
  #           :through    => :aa_residues,
  #           :source     => :atoms
  #
  # has_many  :na_atoms,
  #           :through    => :na_residues,
  #           :source     => :atoms
  #
  # has_many  :dna_atoms,
  #           :through    => :dna_residues,
  #           :source     => :atoms
  #
  # has_many  :rna_atoms,
  #           :through    => :rna_residues,
  #           :source     => :atoms
  #
  # has_many  :hna_atoms,
  #           :through    => :hna_residues,
  #           :source     => :atoms
  #
  # has_many  :het_atoms,
  #           :through    => :het_residues,
  #           :source     => :atoms
  #
  # has_many  :contacts,
  #           :through    => :atoms
  #
  # has_many  :contacting_atoms,
  #           :through    => :contacts
  #
  # has_many  :hbonds_as_donor,
  #           :through    => :atoms
  #
  # has_many  :hbonds_as_acceptor,
  #           :through    => :atoms
  #
  # has_many  :hbonding_donors,
  #           :through    => :hbonds_as_acceptor
  #
  # has_many  :hbonding_acceptors,
  #           :through    => :hbonds_as_donor
  #
  # has_many  :whbonds,
  #           :through    => :atoms
  #
  # has_many  :whbonding_atoms,
  #           :through    => :whbonds
end
