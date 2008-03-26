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
    residues = []
    chains.each { |c| residues.concat(c.residues) }
    residues
  end

  def aa_residues
    aa_residues = []
    aa_chains.each { |c| aa_residues.concat(c.residues) }
    aa_residues
  end

  def na_residues
    na_residues = []
    na_chains.each { |c| na_residues.concat(c.residues) }
    na_residues
  end

  def atoms
    atoms = []
    residues.each { |r| atoms.concat(r.atoms) }
    atoms
  end

  def aa_atoms
    aa_atoms = []
    aa_residues.each { |r| aa_atoms.concat(r.atoms) }
    aa_atoms
  end

  def na_atoms
    na_atoms = []
    na_residues.each { |r| na_atoms.concat(r.atoms) }
    na_atoms
  end
end
