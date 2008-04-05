class Residue < ActiveRecord::Base

  include Bipa::Constants
  include Bipa::ComposedOfAtoms

  belongs_to  :chain,
              :class_name   => "Chain",
              :foreign_key  => "chain_id"

  belongs_to  :chain_interface

  has_many  :atoms,
            :class_name   => "Atom",
            :foreign_key  => "residue_id",
            :dependent    => :destroy

  has_many  :contacts,
            :through      => :atoms

  # has_many  :contacting_atoms,
  #          :through      => :atoms

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

  def justified_residue_name
    residue_name.rjust(3)
  end

  def justified_residue_code
    residue_code.to_s.rjust(4, '0')
  end
end # class Residue


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
  
  %w(unbound bound delta).each do |stat|
    class_eval <<-END
      def relative_#{stat}_asa
        @relative_#{stat}_asa ||= if AminoAcids::Residues::STANDARD.include?(residue_name)
          atoms.inject(0) { |s, a| a.#{stat}_asa ? s + a.#{stat}_asa : s } /
            AminoAcids::Residues::STANDARD_ASA[residue_name]
        else
          raise "Unknown residue type: \#{id}, \#{residue_name}"
        end
      end
    END
  end
end


class NaResidue < StdResidue
end


class DnaResidue < NaResidue
end


class RnaResidue < NaResidue
end
