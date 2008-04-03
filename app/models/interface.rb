class Interface < ActiveRecord::Base

  include Bipa::Constants
  include Bipa::ComposedOfResidues
end


class DomainInterface < Interface

  include Bipa::NucleicAcidBinding

  belongs_to  :domain,
              :class_name   => "ScopDomain",
              :foreign_key  => 'scop_id'

  has_many  :residues
  
  before_save :update_singlet_propensities,
              :update_sse_propensities

  # Callbacks
  def update_singlet_propensities
    AminoAcids::Residues::STANDARD.each do |aa|
      self.send("singlet_propensity_of_#{aa}=", singlet_propensity_of(aa))
    end
  end

  def update_sse_propensities
    DSSP::SSES.map(&:downcase).each do |sse|
      self.send("sse_propensity_of_#{sse}=", sse_propensity_of(sse))
    end
  end

  AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa|
    %w(hbond whbond contact).each do |int|
      %w(sugar phosphate).each do |moiety|

        before_save :"update_frequency_of_#{int}_between_#{aa}_and_#{moiety}"

        define_method "update_frequency_of_#{int}_between_#{aa}_and_#{moiety}" do
          self.send("frequency_of_#{int}_between_#{aa}_and_#{moiety}=",
                    self.send("frequency_of_#{int}_between_#{moiety}_and_", aa))
        end
      end

      before_save :"update_frequency_of_#{int}_between_#{aa}_and_nucleic_acids"

      define_method :"update_frequency_of_#{int}_between_#{aa}_and_nucleic_acids" do
        self.send("frequency_of_#{int}_between_#{aa}_and_nucleic_acids=",
                  self.send("frequency_of_#{int}_between_nucleic_acids_and_", aa))
      end
    end
  end

  def singlet_propensity_of(res)
    result = ((asa_of_residue(res) / atoms.to_a.sum(&:delta_asa)) /
              (domain.asa_of_residue(res) / domain.unbound_asa))
    result.to_f.nan? ? 1 : result
  end

  def sse_propensity_of(sse)
    result = ((asa_of_sse(sse) / atoms.to_a.sum(&:delta_asa)) /
              (domain.asa_of_sse(sse) / domain.unbound_asa))
    result.to_f.nan? ? 1 : result
  end

  def frequency_of_hbond_between(aa, na)
    aa.upcase!
    na.upcase!
    sum = 0

    hbonds_as_donor.each do |h|
      if h.hbonding_donor.residue.residue_name == aa &&
        h.hbonding_acceptor.residue.residue_name == na &&
        !NucleicAcids::Atoms::SUGAR.include?(h.hbonding_acceptor.atom_name) &&
        !NucleicAcids::Atoms::PHOSPHATE.include?(h.hbonding_acceptor.atom_name)
        sum += 1
      end
    end
    hbonds_as_acceptor.each do |h|
      if h.hbonding_acceptor.residue.residue_name == aa &&
        h.hbonding_donor.residue.residue_name == na &&
        !NucleicAcids::Atoms::SUGAR.include?(h.hbonding_donor.atom_name) &&
        !NucleicAcids::Atoms::PHOSPHATE.include?(h.hbonding_donor.atom_name)
        sum += 1
      end
    end
    sum
  end

  def frequency_of_whbond_between(aa, na)
    aa.upcase!
    na.upcase!
    sum = 0

    whbonds.each do |wh|
      if wh.atom.residue.residue_name == aa &&
        wh.whbonding_atom.residue.residue_name == na &&
        !NucleicAcids::Atoms::SUGAR.include?(wh.whbonding_atom) &&
        !NucleicAcids::Atoms::SUGAR.include?(wh.whbonding_atom)
        sum += 1
      end
    end
    sum
  end

  def frequency_of_contact_between(aa, na)
    aa.upcase!
    na.upcase!
    sum = 0

    contacts.each do |c|
      if c.atom.residue.residue_name == aa &&
        c.contacting_atom.residue.residue_name == na &&
        !NucleicAcids::Atoms::SUGAR.include?(c.contacting_atom) &&
        !NucleicAcids::Atoms::SUGAR.include?(c.contacting_atom)
        sum += 1
      end
    end
    sum - frequency_of_hbond_between(aa, na)
  end

  def frequency_of_hbond_between_sugar_and_(aa)
    aa.upcase!
    sum = 0

    hbonds_as_donor.each do |h|
      if h.hbonding_donor.residue.residue_name == aa &&
        NucleicAcids::Atoms::SUGAR.include?(h.hbonding_acceptor.atom_name)
        sum += 1
      end
    end
    hbonds_as_acceptor.each do |h|
      if h.hbonding_acceptor.residue.residue_name == aa &&
        NucleicAcids::Atoms::SUGAR.include?(h.hbonding_donor.atom_name)
        sum += 1
      end
    end
    sum
  end

  def frequency_of_whbond_between_sugar_and_(aa)
    aa.upcase!
    sum = 0

    whbonds.each do |wh|
      if wh.atom.residue.residue_name == aa &&
        NucleicAcids::Atoms::SUGAR.include?(wh.whbonding_atom.atom_name)
        sum += 1
      end
    end
    sum
  end

  def frequency_of_contact_between_sugar_and_(aa)
    aa.upcase!
    sum = 0

    contacts.each do |c|
      if c.atom.residue.residue_name == aa &&
        NucleicAcids::Atoms::SUGAR.include?(c.contacting_atom.atom_name)
        sum += 1
      end
    end
    sum
  end

  def frequency_of_hbond_between_phosphate_and_(aa)
    aa.upcase!
    sum = 0

    hbonds_as_donor.each do |h|
      if h.hbonding_donor.residue.residue_name == aa &&
        NucleicAcids::Atoms::PHOSPHATE.include?(h.hbonding_acceptor.atom_name)
        sum += 1
      end
    end
    hbonds_as_acceptor.each do |h|
      if h.hbonding_acceptor.residue.residue_name == aa &&
        NucleicAcids::Atoms::PHOSPHATE.include?(h.hbonding_donor.atom_name)
        sum += 1
      end
    end
    sum
  end

  def frequency_of_whbond_between_phosphate_and_(aa)
    aa.upcase!
    sum = 0

    whbonds.each do |wh|
      if wh.atom.residue.residue_name == aa &&
        NucleicAcids::Atoms::PHOSPHATE.include?(wh.whbonding_atom.atom_name)
        sum += 1
      end
    end
    sum
  end

  def frequency_of_contact_between_phosphate_and_(aa)
    aa.upcase!
    sum = 0

    contacts.each do |c|
      if c.atom.residue.residue_name == aa &&
        NucleicAcids::Atoms::PHOSPHATE.include?(c.contacting_atom.atom_name)
        sum += 1
      end
    end
    sum
  end

  def frequency_of_hbond_between_amino_acids_and_(na)
    na.upcase!
    sum = 0

    AminoAcids::Residues::STANDARD.each do |aa|
      sum += frequency_of_hbond_between(aa, na)
    end
    sum
  end

  def frequency_of_whbond_between_amino_acids_and_(na)
    na.upcase!
    sum = 0

    AminoAcids::Residues::STANDARD.each do |aa|
      sum += frequency_of_whbond_between(aa, na)
    end
    sum
  end

  def frequency_of_contact_between_amino_acids_and_(na)
    na.upcase!
    sum = 0

    AminoAcids::Residues::STANDARD.each do |aa|
      sum += frequency_of_contact_between(aa, na)
    end
    sum
  end

end # class DomainInterface


class DomainDnaInterface < DomainInterface

  %w(hbond whbond contact).each do |intact|
    NucleicAcids::Dna::Residues::STANDARD.map(&:downcase).each do |dna|

      before_save :"update_frequency_of_#{intact}_between_amino_acids_and_#{dna}"

      define_method :"update_frequency_of_#{intact}_between_amino_acids_and_#{dna}" do
        self.send("frequency_of_#{intact}_between_amino_acids_and_#{dna}=",
                  self.send("frequency_of_#{intact}_between_amino_acids_and_", dna))
      end

      AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa|

        before_save :"update_frequency_of_#{intact}_between_#{aa}_and_#{dna}"

        define_method :"update_frequency_of_#{intact}_between_#{aa}_and_#{dna}" do
          self.send("frequency_of_#{intact}_between_#{aa}_and_#{dna}=",
                    self.send("frequency_of_#{intact}_between", aa, dna))
        end
      end
    end
  end

  def frequency_of_hbond_between_nucleic_acids_and_(aa)
    aa.upcase!
    sum = 0
    NucleicAcids::Dna::Residues::STANDARD.each do |dna|
      sum += frequency_of_hbond_between(aa, dna)
    end
    sum += frequency_of_hbond_between_sugar_and_(aa)
    sum += frequency_of_hbond_between_phosphate_and_(aa)
  end

  def frequency_of_whbond_between_nucleic_acids_and_(aa)
    aa.upcase!
    sum = 0
    NucleicAcids::Dna::Residues::STANDARD.each do |dna|
      sum += frequency_of_whbond_between(aa, dna)
    end
    sum += frequency_of_whbond_between_sugar_and_(aa)
    sum += frequency_of_whbond_between_phosphate_and_(aa)
  end

  def frequency_of_contact_between_nucleic_acids_and_(aa)
    aa.upcase!
    sum = 0
    NucleicAcids::Dna::Residues::STANDARD.each do |dna|
      sum += frequency_of_contact_between(aa, dna)
    end
    sum += frequency_of_contact_between_sugar_and_(aa)
    sum += frequency_of_contact_between_phosphate_and_(aa)
  end
end # class DomainDnaInterface


class DomainRnaInterface < DomainInterface

  %w(hbond whbond contact).each do |int|
    NucleicAcids::Rna::Residues::STANDARD.map(&:downcase).each do |rna|

      before_save :"update_frequency_of_#{int}_between_amino_acids_and_#{rna}"

      define_method :"update_frequency_of_#{int}_between_amino_acids_and_#{rna}" do
        self.send("frequency_of_#{int}_between_amino_acids_and_#{rna}=",
                  self.send("frequency_of_#{int}_between_amino_acids_and_", rna))
      end

      AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa|

        before_save :"update_frequency_of_#{int}_between_#{aa}_and_#{rna}"

        define_method :"update_frequency_of_#{int}_between_#{aa}_and_#{rna}" do
          self.send("frequency_of_#{int}_between_#{aa}_and_#{rna}=",
                    self.send("frequency_of_#{int}_between", aa, rna))
        end
      end
    end
  end

  def frequency_of_hbond_between_nucleic_acids_and_(aa)
    aa.upcase!
    sum = 0
    NucleicAcids::Rna::Residues::STANDARD.each do |rna|
      sum += frequency_of_hbond_between(aa, rna)
    end
    sum += frequency_of_hbond_between_sugar_and_(aa)
    sum += frequency_of_hbond_between_phosphate_and_(aa)
  end

  def frequency_of_whbond_between_nucleic_acids_and_(aa)
    aa.upcase!
    sum = 0
    NucleicAcids::Rna::Residues::STANDARD.each do |rna|
      sum += frequency_of_whbond_between(aa, rna)
    end
    sum += frequency_of_whbond_between_sugar_and_(aa)
    sum += frequency_of_whbond_between_phosphate_and_(aa)
  end

  def frequency_of_contact_between_NucleicAcids_and_(aa)
    aa.upcase!
    sum = 0
    NucleicAcids::Rna::Residues::STANDARD.each do |rna|
      sum += frequency_of_contact_between(aa, rna)
    end
    sum += frequency_of_contact_between_sugar_and_(aa)
    sum += frequency_of_contact_between_phosphate_and_(aa)
  end
end # class DomainRnaInterface


class ChainInterface < Interface

  belongs_to :chain

  has_many  :residues
end


class ChainDnaInterface < ChainInterface
end


class ChainRnaInterface < ChainInterface
end
