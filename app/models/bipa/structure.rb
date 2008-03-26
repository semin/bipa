class Bipa::Structure < ActiveRecord::Base

  is_indexed :fields => ["pdb_code", "classification", "title", "exp_method", "resolution"]

  has_many  :models,
            :class_name   => "Bipa::Model",
            :foreign_key  => "structure_id",
            :dependent    => :destroy

  def chains
    chains = []
    models.each { |m| chains.concat(m.chains) }
    chains
  end

  def residues
    residues = []
    models.each { |m| residues.concat(m.residues) }
    residues
  end

  def atoms
    atoms = []
    models.each { |m| atoms.concat(m.atoms) }
    atoms
  end

  def aa_atoms
    aa_atoms = []
    models.each { |m| aa_atoms.concat(m.aa_atoms) }
    aa_atoms
  end

  def na_atoms
    na_atoms = []
    models.each { |m| na_atoms.concat(m.na_atoms) }
    na_atoms
  end
end
