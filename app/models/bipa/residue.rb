class Bipa::Residue < ActiveRecord::Base

  include Bipa::Usr
  include Bipa::Constants
  include Bipa::ComposedOfAtoms

  belongs_to  :chain,
              :class_name   => "Bipa::Chain",
              :foreign_key  => "chain_id"

  belongs_to  :chain_interface,
              :class_name   => "Bipa::ChainInterface",
              :foreign_key  => "chain_interface_id"

  has_many  :atoms,
            :class_name   => "Bipa::Atom",
            :dependent    => :destroy

  has_many  :contacts,
            :through      => :atoms

  has_many  :contacting_atoms,
            :through      => :contacts

  has_many  :whbonds,
            :through      => :atoms

  has_many  :whbonding_atoms,
            :through      => :atoms

  has_many  :hbonds_as_donor,
            :through      => :atoms

  has_many  :hbonds_as_acceptor,
            :through      => :atoms

  has_many  :hbonding_donors,
            :through      => :atoms

  has_many  :hbonding_acceptors,
            :through      => :atoms

  # ASA related
  def on_surface?
    surface_atoms.size > 0
  end

  def on_interface?
    interface_atoms.size > 0
  end

  def buried?
    !on_surface?
  end

  # Residue specific properties
  def dna?
    self.class == Bipa::DnaResidue
  end

  def rna?
    self.class == Bipa::RnaResidue
  end

  def aa?
    self.class == Bipa::AaResidue
  end

  def justified_residue_name
    residue_name.rjust(3)
  end

  def justified_residue_code
    residue_code.to_s.rjust(4, '0')
  end

  def one_letter_code
    AminoAcids::Residues::ONE_LETTER_CODE[residue_name] or
    raise "Error: No one letter code for residue: #{residue_name}"
  end
end # class Bipa::Residue


class Bipa::StdResidue < Bipa::Residue
end


class Bipa::HetResidue < Bipa::Residue
end


class Bipa::AaResidue < Bipa::StdResidue

  include Bipa::NucleicAcidBinding

  belongs_to  :domain,
              :class_name   => "Bipa::ScopDomain",
              :foreign_key  => "scop_id"

  belongs_to  :domain_interface,
              :class_name   => "Bipa::DomainInterface",
              :foreign_key  => "domain_interface_id"

  def relative_unbound_asa
    @relative_unbound_asa ||=
      if AminoAcids::Residues::STANDARD.include? residue_name
        atoms.inject(0) { |s, a| a.unbound_asa ? s + a.unbound_asa : s } /
          AminoAcids::Residues::STANDARD_ASA[residue_name]
      else
        raise "Unknown residue type: #{id}, #{residue_name}"
      end
  end

  def relative_bound_asa
    @relative_bound_asa ||=
      if AminoAcids::Residues::STANDARD.include? residue_name
        atoms.inject(0) { |s, a| a.bound_asa ? s + a.bound_asa : s } /
          AminoAcids::Residues::STANDARD_ASA[residue_name]
      else
        raise "Unknown residue type: #{id}, #{residue_name}"
      end
  end

  def relative_delta_asa
    @relative_delta_asa ||=
      if AminoAcids::Residues::STANDARD.include? residue_name
        atoms.inject(0) { |s, a| a.delta_asa ? s + a.delta_asa : s } /
          AminoAcids::Residues::STANDARD_ASA[residue_name]
      else
        raise "Unknown residue type: #{id}, #{residue_name}"
      end
  end
end


class Bipa::NaResidue < Bipa::StdResidue
end


class Bipa::DnaResidue < Bipa::NaResidue
end


class Bipa::RnaResidue < Bipa::NaResidue
end
