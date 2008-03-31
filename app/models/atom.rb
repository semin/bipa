class Atom < ActiveRecord::Base

  include Bipa::NucleicAcidBinding

  belongs_to  :residue
  
  has_many  :contacts,
            :dependent    => :destroy

  has_many  :contacting_atoms,
            :through      => :contacts

  has_many  :whbonds,
            :dependent    => :destroy

  has_many  :whbonding_atoms,
            :through      => :whbonds

  has_many  :hbonds_as_donor,
            :dependent    => :destroy

  has_many  :hbonds_as_acceptor,
            :dependent    => :destroy

  has_many  :hbonding_donors,
            :through      => :hbonds_as_acceptor

  has_many  :hbonding_acceptors,
            :through      => :hbonds_as_donor

  # ASA related
  def on_surface?
    unbound_asa ? unbound_asa > MIN_SRFATM_SASA : false
  end

  def buried?
    not on_surface?
  end

  def on_interface?
    delta_asa ? delta_asa > MIN_INTATM_DASA : false
  end

  # Atom specific properties
  def aa?
    residue.aa?
  end

  def dna?
    residue.dna?
  end

  def rna?
    residue.rna?
  end

  def na?
    dna? || rna?
  end

  def polar?
    atom_name =~ /O|N/
  end

  def on_major_groove?
    raise "Not implemented yet"
  end

  def on_minor_groove?
    raise "Not implemented yet"
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
    sprintf("%-6s%5d %-4s%-1s%3s %-1s%4d%-1s   %8.3f%8.3f%8.3f%6.2f%6.2f      %-4s%2s%-2s\n",
            'ATOM',
            atom_code,
            justified_atom_name,
            altloc,
            residue.residue_name,
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