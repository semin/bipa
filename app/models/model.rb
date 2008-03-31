class Model < ActiveRecord::Base

  include Bipa::Usr
  include Bipa::ComposedOfResidues
  include Bipa::ComposedOfAtoms

  belongs_to  :structure

  has_many  :chains,
            :dependent => :destroy

  has_many  :aa_chains

  has_many  :na_chains

  has_many  :dna_chains

  has_many  :rna_chains

  has_many  :hna_chains

  has_many  :het_chains

  def residues
    @residues ||= chains.inject([]) { |s, c| s.concat(c.residues) }
  end

  def aa_residues
    residues.select { |r| r.is_a?(AaResidue) }
  end

  def na_residues
    residues.select { |r| r.is_a?(NaResidue) }
  end

  def atoms
    @atoms ||= residues.inject([]) { |s, r| s.concat(r.atoms) }
  end

  def aa_atoms
    aa_atoms = []
    aa_residues.each { |r| aa_atoms.concat(r.atoms) }
  end

  def na_atoms
    na_atoms = []
    na_residues.each { |r| na_atoms.concat(r.atoms) }
    na_atoms
  end
end
