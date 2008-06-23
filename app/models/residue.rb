class Residue < ActiveRecord::Base

  include Bipa::Constants
#  include Bipa::ComposedOfAtoms

  belongs_to  :chain,
              :class_name   => "Chain",
              :foreign_key  => "chain_id"

  belongs_to  :domain,
              :class_name   => "ScopDomain",
              :foreign_key  => "scop_id"

  belongs_to  :chain_interface

  has_one   :structure,
            :through      => :chain

  has_many  :atoms,
            :dependent    => :destroy

  has_many  :contacts,
            :through      => :atoms

  has_many  :whbonds,
            :through      => :atoms

  has_many  :hbonds_as_donor,
            :through      => :atoms

  has_many  :hbonds_as_acceptor,
            :through      => :atoms

  has_many  :hbonding_donors,
            :through      => :hbonds_as_acceptor

  has_many  :hbonding_acceptors,
            :through      => :hbonds_as_donor

  has_many  :positions

  has_one :dssp,
          :class_name   => "Dssp",
          :foreign_key  => "residue_id"

  delegate :sse, :to => :dssp

  # this is for regular 'residue' types except 'AaResidue',
  # which has its own definition of surface residue
  def on_surface?
    surface_atoms.size > 0
  end

  # this is for regular 'residue' types except 'AaResidue',
  # which has its own definition of 'interface residue'
  def on_interface?
    interface_atoms.size > 0
  end

  def buried?
    !on_surface?
  end

  def aa?
    is_a?(AaResidue)
  end

  def na?
    is_a?(NaResidue)
  end

  def dna?
    is_a?(DnaResidue)
  end

  def rna?
    is_a?(RnaResidue)
  end

  def het?
    is_a?(HetResidue)
  end

  def water?
    residue_name == "HOH"
  end

  def justified_residue_name
    residue_name.rjust(3)
  end

  def justified_residue_code
    residue_code.to_s.rjust(4, '0')
  end
end # class Residue


class StdResidue < Residue

  has_many  :atoms,
            :class_name   => "StdAtom",
            :foreign_key  => "residue_id"
end


class HetResidue < Residue

  has_many  :atoms,
            :class_name   => "HetAtom",
            :foreign_key  => "residue_id"

  def one_letter_code
    AminoAcids::Residues::ONE_LETTER_CODE[residue_name] or "X"
  end
end


class AaResidue < StdResidue

  belongs_to  :domain_interface,
              :class_name   => "DomainInterface",
              :foreign_key  => "domain_interface_id"

  belongs_to  :res_map,
              :class_name   => "ResMap",
              :foreign_key  => "res_map_id"

  belongs_to  :residue_map,
              :class_name   => "ResidueMap",
              :foreign_key  => "residue_map_id"

  def on_surface?
    relative_unbound_asa >= MIN_SURFACE_RESIDUE_RELATIVE_ASA
  end

  def on_interface?
    delta_asa >= MIN_INTERFACE_RESIDUE_DELTA_ASA
  end

  def one_letter_code
    AminoAcids::Residues::ONE_LETTER_CODE[residue_name] or
    raise "No one letter code for residue: #{residue_name}"
  end

  %w(unbound bound delta).each do |state|
    class_eval <<-END
      def relative_#{state}_asa
        if AminoAcids::Residues::STANDARD.include?(residue_name)
          atoms.inject(0) { |s, a| a.#{state}_asa ? s + a.#{state}_asa : s } /
            AminoAcids::Residues::STANDARD_ASA[residue_name]
        else
          raise "Unknown residue type: \#{id}, \#{residue_name}"
        end
      end
      memoize :relative_#{state}_asa
    END
  end
end


class NaResidue < StdResidue
end


class DnaResidue < NaResidue
end


class RnaResidue < NaResidue
end
