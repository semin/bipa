class Model < ActiveRecord::Base

  include Bipa::ComposedOfResidues

  belongs_to  :structure

  has_many  :chains,
            :dependent    => :destroy

  has_many  :aa_chains

  has_many  :na_chains

  has_many  :dna_chains

  has_many  :rna_chains

  has_many  :hna_chains

  has_many  :pseudo_chains

  has_many  :residues,
            :through    => :chains

  has_many  :std_residues,
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

  has_many  :water_residues,
            :through    => :chains

  def domains
    aa_chains.inject([]) { |s, a| s.concat(a.domains) }
  end
end
