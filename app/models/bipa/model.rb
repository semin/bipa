class Bipa::Model < ActiveRecord::Base

  include Bipa::Usr
  include Bipa::ComposedOfResidues
  include Bipa::ComposedOfAtoms

  belongs_to  :structure,
              :class_name   => "Bipa::Structure",
              :foreign_key  => "structure_id"

  has_many  :chains,
            :class_name => "Bipa::Chain",
            :dependent  => :destroy

  has_many  :residues,
            :through    => :chains

  has_many  :atoms,
            :through    => :residues

  has_many  :contacts,
            :through    => :atoms

  has_many  :contacting_atoms,
            :through    => :contacts

  has_many  :whbonds,
            :through    => :atoms

  has_many  :whbonding_atoms,
            :through    => :whbonds

  has_many  :hbonds_as_donor,
            :through    => :atoms

  has_many  :hbonds_as_acceptor,
            :through    => :atoms

  has_many  :hbonding_donors,
            :through    => :hbonds_as_acceptor

  has_many  :hbonding_acceptors,
            :through    => :hbonds_as_donor

  has_many  :aa_chains,
            :class_name => "Bipa::AaChain",


  has_many  :domains,
            :through    => :aa_chains,
            :uniq       => true

  has_many  :aa_residues,
            :through    => :aa_chains,
            :source     => :residues

  has_many  :aa_atoms,
            :through    => :aa_residues,
            :source     => :atoms

  has_many  :dna_chains,
            :class_name => "Bipa::DnaChain"

  has_many  :dna_residues,
            :through    => :dna_chains,
            :source     => :residues

  has_many  :dna_atoms,
            :through    => :dna_residues,
            :source     => :atoms

  has_many  :rna_chains,
            :class_name => "Bipa::RnaChain"

  has_many  :rna_residues,
            :through    => :rna_chains,
            :source     => :residues

  has_many  :rna_atoms,
            :through    => :rna_residues,
            :source     => :atoms

  has_many  :hna_chains,
            :class_name => "Bipa::HnaChain"

  has_many  :hna_dna_residues,
            :through    => :hna_chains,
            :source     => :dna_residues

  has_many  :hna_dna_atoms,
            :through    => :hna_dna_residues,
            :source     => :atoms

  has_many  :hna_rna_residues,
            :through    => :hna_chains,
            :source     => :rna_residues

  has_many  :hna_rna_atoms,
            :through    => :hna_rna_residues,
            :source     => :atoms

  has_many  :het_chains,
            :class_name => "Bipa::HnaChain"

  has_many  :het_residues,
            :through    => :het_chains,
            :source     => :residues

  has_many  :het_atoms,
            :through    => :het_residues,
            :source     => :atoms
end
