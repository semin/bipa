class Atom < ActiveRecord::Base

  include Bipa::Constants
  include Bipa::NucleicAcidBinding

  belongs_to  :residue

  has_many  :vdw_contacts,
            :dependent    => :destroy

  has_many  :vdw_contacting_atoms,
            :through      => :vdw_contacts

  has_many  :whbonds,
            :dependent    => :destroy

  has_many  :whbonding_atoms,
            :through      => :whbonds

  has_many  :hbplus_as_donor,
            :class_name   => "Hbplus",
            :foreign_key  => "donor_id",
            :dependent    => :destroy

  has_many  :hbplus_as_acceptor,
            :class_name   => "Hbplus",
            :foreign_key  => "acceptor_id",
            :dependent    => :destroy

  has_many  :hbplus_donors,
            :through      => :hbplus_as_acceptor,
            :source       => :donor

  has_many  :hbplus_acceptors,
            :through      => :hbplus_as_donor,
            :source       => :acceptor

  has_many  :hbonds_as_donor,
            :class_name   => "Hbond",
            :foreign_key  => "donor_id",
            :dependent    => :destroy

  has_many  :hbonds_as_acceptor,
            :class_name   => "Hbond",
            :foreign_key  => "acceptor_id",
            :dependent    => :destroy

  has_many  :hbonding_donors,
            :through      => :hbonds_as_acceptor,
            :source       => :donor

  has_many  :hbonding_acceptors,
            :through      => :hbonds_as_donor,
            :source       => :acceptor

  has_one   :naccess

  has_one   :potential

  delegate  :aa?,
            :dna?,
            :rna?,
            :na?,
            :het?,
            :water?,
            :to => :residue,
            :allow_nil => true

  delegate  :unbound_asa,
            :bound_asa,
            :delta_asa,
            :radius,
            :to => :naccess,
            :allow_nil => true

  delegate  :formal_charge,
            :partial_charge,
            :atom_potential,
            :asa_potential,
            :to => :potential,
            :allow_nil => true

  named_scope :surface, lambda { |*args|
    { :conditions => ["unbound_asa > ?", (args.first || configatron.min_surface_atom_asa)] }
  }

  named_scope :buried, lambda { |*args|
    { :conditions => ["unbound_asa <= ?", (args.first || configatron.min_surface_atom_asa)] }
  }

  named_scope :interface, lambda { |*args|
    { :conditions => ["delta_asa > ?", (args.first || configatron.min_interface_atom_delta_asa)] }
  }

  named_scope :polar, lambda { |*args|
    { :conditions => ["atom_name like '%N%' OR atom_name like '%O%'"] }
  }

  # ASA related
  def on_surface?
    naccess ? (unbound_asa > configatron.min_surface_atom_asa) : false
  end

  def buried?
    !on_surface?
  end

  def on_interface?
    naccess ? (delta_asa > configatron.min_interface_atom_delta_asa) : false
  end

  def polar?
    atom_name =~ /O|N/
  end

  def on_major_groove?
    residue.dna? && NucleicAcids::Dna::Atoms::MAJOR_GROOVE[residue.residue_name].include?(atom_name)
  end

  def on_minor_groove?
    residue.dna? && NucleicAcids::Dna::Atoms::MINOR_GROOVE[residue.residue_name].include?(atom_name)
  end

  def sidechain?
    moiety == "sidechain"
  end

  def backbone?
    moiety == "backbone"
  end

  def base?
    moiety == "base"
  end

  def sugar?
    moiety == "sugar"
  end

  def phosphate?
    moiety == "phosphate"
  end

  def justified_atom_name
    an = self[:atom_name]
    return an[0, 4] if an.length >= 4

    case an.length
    when 0
      return '    '
    when 1
      return ' ' + an + '  '
    when 2
      if /\A[0-9]/ =~ an then
        return sprintf('%-4s', an)
      elsif /[0-9]\z/ =~ an then
        return sprintf(' %-3s', an)
      end
    when 3
      if /\A[0-9]/ =~ an then
        return sprintf('%-4s', an)
      end
    end

    # ambiguous case for two- or three-letter name
    elem = self.element.strip
    if elem.size > 0 and i = an.index(elem) then
      if i == 0 and elem.size == 1 then
        return sprintf(' %-3s', an)
      else
        return sprintf('%-4s', an)
      end
    end
    if self.kind_of?(HetAtom)
      if /\A(B[^AEHIKR]|C[^ADEFLMORSU]|F[^EMR]|H[^EFGOS]|I[^NR]|K[^R]|N[^ABDEIOP]|O[^S]|P[^ABDMORTU]|S[^BCEGIMNR]|V|W|Y[^B])/ =~ an
        return sprintf(' %-3s', an)
      else
        return sprintf('%-4s', an)
      end
    else # StdAtom
      if (/\A[CHONSP]/ =~ an)
        return sprintf(' %-3s', an)
      else
        return sprintf('%-4s', an)
      end
    end
    # could not be reached here
    raise "Cannot justify the atom name: #{an}"
  end

  def to_pdb
    sprintf("%-6s%5d %-4s%-1s%3s %-1s%4d%-1s   %8.3f%8.3f%8.3f%6.2f%6.2f      %-4s%2s%-2s",
            'ATOM',
            atom_code,
            justified_atom_name,
            altloc,
            residue.justified_residue_name,
            residue.chain.chain_code,
            residue.residue_code,
            residue.icode,
            x, y, z,
            occupancy,
            tempfactor,
            "",
            element,
            charge)
  end

  # Vector calculation & KDTree algorithm related
  def xyz
    @xyz ||= [x, y, z]
  end

  def size
    xyz.size
  end

  def dimension(index)
    xyz[index]
  end

  def -(other)
    c_distance(x, y, z, other.x, other.y, other.z)
  end

  inline do |builder|
    builder.include "<math.h>"
    builder.c <<-C_CODE
        double c_distance(double sx, double sy, double sz,
                          double ox, double oy, double oz) {
          return  sqrt( pow(sx - ox, 2) +
                        pow(sy - oy, 2) +
                        pow(sz - oz, 2) );
        }
    C_CODE
  end
end # class Atom

class StdAtom < Atom
end

class HetAtom < Atom
end
