class Residue < ActiveRecord::Base

  include Bipa::Constants
  include Bipa::ComposedOfAtoms

  belongs_to  :chain

  belongs_to  :chain_interface

  has_many  :atoms,
            :dependent    => :destroy

  has_many  :contacts,
            :through      => :atoms
  
  has_many  :whbonds,
            :through      => :atoms
  
  # has_many  :whbonding_atoms,
  #           :through      => :whbonds
  
  has_many  :hbonds_as_donor,
            :through      => :atoms
  
  has_many  :hbonds_as_acceptor,
            :through      => :atoms
  
  # has_many  :hbonding_donors,
  #           :through      => :hbonds_as_acceptor
  # 
  # has_many  :hbonding_acceptors,
  #           :through      => :hbonds_as_donor

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
    self.class == DnaResidue
  end

  def rna?
    self.class == RnaResidue
  end

  def aa?
    self.class == AaResidue
  end

  def justified_residue_name
    residue_name.rjust(3)
  end

  def justified_residue_code
    residue_code.to_s.rjust(4, '0')
  end
end # class Bipa::Residue


class StdResidue < Residue
end


class HetResidue < Residue
end


class AaResidue < StdResidue

  include Bipa::NucleicAcidBinding

  belongs_to  :domain,
              :class_name   => "ScopDomain",
              :foreign_key  => "scop_id"

  belongs_to  :domain_interface,
              :class_name   => "DomainInterface",
              :foreign_key  => "domain_interface_id"

  def one_letter_code
    AminoAcids::Residues::ONE_LETTER_CODE[residue_name] or
    raise "No one letter code for residue: #{residue_name}"
  end
  
  def relative_unbound_asa
    @relative_unbound_asa ||= if AminoAcids::Residues::STANDARD.include?(residue_name)
      atoms.inject(0) { |s, a| a.unbound_asa ? s + a.unbound_asa : s } /
        AminoAcids::Residues::STANDARD_ASA[residue_name]
    else
      raise "Unknown residue type: #{id}, #{residue_name}"
    end
  end

  def relative_bound_asa
    @relative_bound_asa ||= if AminoAcids::Residues::STANDARD.include?(residue_name)
      atoms.inject(0) { |s, a| a.bound_asa ? s + a.bound_asa : s } /
        AminoAcids::Residues::STANDARD_ASA[residue_name]
    else
      raise "Unknown residue type: #{id}, #{residue_name}"
    end
  end

  def relative_delta_asa
    @relative_delta_asa ||= if AminoAcids::Residues::STANDARD.include?(residue_name)
      atoms.inject(0) { |s, a| a.delta_asa ? s + a.delta_asa : s } /
        AminoAcids::Residues::STANDARD_ASA[residue_name]
    else
      raise "Unknown residue type: #{id}, #{residue_name}"
    end
  end
end


class NaResidue < StdResidue
end


class DnaResidue < NaResidue
end


class RnaResidue < NaResidue
end
