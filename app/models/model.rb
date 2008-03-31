class Bipa::Model < ActiveRecord::Base

  include Bipa::Usr
  include Bipa::ComposedOfResidues
  include Bipa::ComposedOfAtoms

  belongs_to  :structure,
              :class_name   => "Bipa::Structure",
              :foreign_key  => "structure_id"

  has_many  :chains,
            :class_name   => "Bipa::Chain",
            :foreign_key  => "model_id",
            :dependent    => :destroy

  has_many  :aa_chains,
            :class_name   => "Bipa::AaChain",
            :foreign_key  => "model_id"

  has_many  :na_chains,
            :class_name   => "Bipa::NaChain",
            :foreign_key  => "model_id"

  has_many  :dna_chains,
            :class_name   => "Bipa::DnaChain",
            :foreign_key  => "model_id"

  has_many  :rna_chains,
            :class_name   => "Bipa::RnaChain",
            :foreign_key  => "model_id"

  has_many  :hna_chains,
            :class_name   => "Bipa::HnaChain",
            :foreign_key  => "model_id"

  has_many  :het_chains,
            :class_name   => "Bipa::HetChain",
            :foreign_key  => "model_id"

  def residues
    @residues ||= chains.inject([]) { |s, c| s.concat(c.residues) }
  end

  def aa_residues
    residues.select { |r| r.is_a?(Bipa::AaResidue) }
  end

  def na_residues
    residues.select { |r| r.is_a?(Bipa::NaResidue) }
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
