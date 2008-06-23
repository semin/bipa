class Model < ActiveRecord::Base

#  include Bipa::ComposedOfResidues

  belongs_to  :structure

  has_many  :chains,
            :dependent    => :destroy

  has_many  :atoms,
            :through => :chains

  has_many  :aa_chains

  has_many  :na_chains

  has_many  :dna_chains

  has_many  :rna_chains

  has_many  :hna_chains

  has_many  :pseudo_chains

  has_many  :residues,
            :through    => :chains

  has_many  :aa_residues,
            :through    => :chains

  has_many  :na_residues,
            :through    => :chains

  has_many  :dna_residues,
            :through    => :chains

  has_many  :rna_residues,
            :through    => :chains

  has_many  :het_residues,
            :through    => :chains

  has_many  :atoms,
            :through    => :chains

  has_many  :contacts,
            :through    => :atoms

  has_many  :whbonds,
            :through    => :atoms

  has_many  :hbonds_as_donor,
            :through    => :atoms

  has_many  :hbonds_as_acceptor,
            :through    => :atoms

  has_many  :hbonding_donors,
            :through    => :hbonds_as_acceptor

  has_many  :hbonding_acceptors,
            :through    => :hbonds_as_donor

  def domains
    aa_chains.inject([]) { |s, a| s.concat(a.domains) }
  end
  memoize :domains
end
