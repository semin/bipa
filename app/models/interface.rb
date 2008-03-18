class Interface < ActiveRecord::Base

  include BIPA::Constants
  include BIPA::USR

  acts_as_cached

  after_save :expire_cache

  lazy_calculate :asa, :polarity

  def calculate_asa
    atoms.to_a.sum(&:delta_asa)
  end

  def calculate_polarity
    atoms.select(&:polar?).to_a.sum(&:delta_asa) / asa
  end

  def asa_of_residue(res)
    residues.inject(0) { |s, r| r.residue_name == res ? s + r.delta_asa : s + 0 }
  end

end


class DomainInterface < Interface

  include BIPA::NucleicAcidBinding

  belongs_to :domain, :class_name => 'ScopDomain', :foreign_key => 'scop_id'

  has_many :residues, :class_name => "AaResidue", :foreign_key => 'domain_interface_id'

  has_many :atoms,              :through => :residues

  has_many :contacts,           :through => :atoms
  has_many :contacting_atoms,   :through => :contacts

  has_many :whbonds,            :through => :atoms
  has_many :whbonding_atoms,    :through => :whbonds

  has_many :hbonds_as_donor,    :through => :atoms
  has_many :hbonds_as_acceptor, :through => :atoms
  has_many :hbonding_donors,    :through => :hbonds_as_acceptor
  has_many :hbonding_acceptors, :through => :hbonds_as_donor

  AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa|
    lazy_calculate :"singlet_propensity_of_#{aa}"

    define_method :"calculate_singlet_propensity_of_#{aa}" do
      calculate_singlet_propensity_of(aa)
    end

    %w(hbond whbond contact).each do |int|
      %w(sugar phosphate).each do |moiety|

        lazy_calculate :"frequency_of_#{int}_between_#{aa}_and_#{moiety}"

        define_method "calculate_frequency_of_#{int}_between_#{aa}_and_#{moiety}" do
          send("frequency_of_#{int}_between_#{moiety}_and_", aa)
        end
      end

      lazy_calculate :"frequency_of_#{int}_between_#{aa}_and_nucleic_acids"

      define_method :"calculate_frequency_of_#{int}_between_#{aa}_and_nucleic_acids" do
        send("frequency_of_#{int}_between_nucleic_acids_and_", aa)
      end
    end
  end

  DSSP::SSES.map(&:downcase).each do |sse|
    lazy_calculate :"sse_propensity_of_#{sse}"

    define_method :"calculate_sse_propensity_of_#{sse}" do
      calculate_sse_propensity_of(sse)
    end
  end

  def calculate_singlet_propensity_of(res)
    result = (asa_of_residue(res) / asa) / (domain.asa_of_residue(res) / domain.unbound_asa)
    result.to_f.nan? ? 1 : result
  end

  def calculate_sse_propensity_of(sse)
    result = ((asa_of_sse(sse) / asa) / (domain.asa_of_sse(sse) / domain.unbound_asa))
    result.to_f.nan? ? 1 : result
  end

  def asa_of_residue(res)
    residues.inject(0) { |s, r| r.residue_name == res ? s + r.delta_asa : s }
  end

  def asa_of_sse(sse)
    residues.inject(0) { |s, r| r.secondary_structure == sse ? s + r.delta_asa : s }
  end

  def frequency_of_hbond_between(aa, na)
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
    sum = 0
    AminoAcids::Residues::STANDARD.each do |aa|
      sum += frequency_of_hbond_between(aa, na)
    end
    sum
  end

  def frequency_of_whbond_between_amino_acids_and_(na)
    sum = 0
    AminoAcids::Residues::STANDARD.each do |aa|
      sum += frequency_of_whbond_between(aa, na)
    end
    sum
  end

  def frequency_of_contact_between_amino_acids_and_(na)
    sum = 0
    AminoAcids::Residues::STANDARD.each do |aa|
      sum += frequency_of_contact_between(aa, na)
    end
    sum
  end

end # class DomainInterface


class DomainDnaInterface < DomainInterface

  %w(hbond whbond contact).each do |int|
    NucleicAcids::DNA::Residues::STANDARD.map(&:downcase).each do |dna|
  	  lazy_calculate :"frequency_of_#{int}_between_amino_acids_and_#{dna}"

      define_method :"calculate_frequency_of_#{int}_between_amino_acids_and_#{dna}" do
        send("frequency_of_#{int}_between_amino_acids_and_", dna)
      end

  	  AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa|
  	    lazy_calculate :"frequency_of_#{int}_between_#{aa}_and_#{dna}"

        define_method :"calculate_frequency_of_#{int}_between_#{aa}_and_#{dna}" do
          send("frequency_of_#{int}_between", aa, dna)
        end
      end
    end
  end

  def frequency_of_hbond_between_nucleic_acids_and_(aa)
    sum = 0
    NucleicAcids::DNA::Residues::STANDARD.map(&:downcase).each do |dna|
      sum += frequency_of_hbond_between(aa, dna)
    end
    sum += frequency_of_hbond_between_sugar_and_(aa)
    sum += frequency_of_hbond_between_phosphate_and_(aa)
    sum
  end

  def frequency_of_whbond_between_nucleic_acids_and_(aa)
    sum = 0
    NucleicAcids::DNA::Residues::STANDARD.map(&:downcase).each do |dna|
      sum += frequency_of_whbond_between(aa, dna)
    end
    sum += frequency_of_whbond_between_sugar_and_(aa)
    sum += frequency_of_whbond_between_phosphate_and_(aa)
    sum
  end

  def frequency_of_contact_between_nucleic_acids_and_(aa)
    sum = 0
    NucleicAcids::DNA::Residues::STANDARD.map(&:downcase).each do |dna|
      sum += frequency_of_contact_between(aa, dna)
    end
    sum += frequency_of_contact_between_sugar_and_(aa)
    sum += frequency_of_contact_between_phosphate_and_(aa)
    sum
  end

end # class DomainDnaInterface


class DomainRnaInterface < DomainInterface

  %w(hbond whbond contact).each do |int|
	  NucleicAcids::RNA::Residues::STANDARD.map(&:downcase).each do |rna|
  	  lazy_calculate :"frequency_of_#{int}_between_amino_acids_and_#{rna}"

      define_method :"calculate_frequency_of_#{int}_between_amino_acids_and_#{rna}" do
        send("frequency_of_#{int}_between_amino_acids_and_", rna)
      end

  	  AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa|
  	    lazy_calculate :"frequency_of_#{int}_between_#{aa}_and_#{rna}"

        define_method :"calculate_frequency_of_#{int}_between_#{aa}_and_#{rna}" do
          send("frequency_of_#{int}_between", aa, rna)
        end
      end
    end
  end

  def frequency_of_hbond_between_nucleic_acids_and_(aa)
    sum = 0
    NucleicAcids::RNA::Residues::STANDARD.map(&:downcase).each do |rna|
      sum += frequency_of_hbond_between(aa, rna)
    end
    sum += frequency_of_hbond_between_sugar_and_(aa)
    sum += frequency_of_hbond_between_phosphate_and_(aa)
    sum
  end

  def frequency_of_whbond_between_nucleic_acids_and_(aa)
    sum = 0
    NucleicAcids::RNA::Residues::STANDARD.map(&:downcase).each do |rna|
      sum += frequency_of_whbond_between(aa, rna)
    end
    sum += frequency_of_whbond_between_sugar_and_(aa)
    sum += frequency_of_whbond_between_phosphate_and_(aa)
    sum
  end

  def frequency_of_contact_between_NucleicAcids_and_(aa)
    sum = 0
    NucleicAcids::RNA::Residues::STANDARD.map(&:downcase).each do |rna|
      sum += frequency_of_contact_between(aa, rna)
    end
    sum += frequency_of_contact_between_sugar_and_(aa)
    sum += frequency_of_contact_between_phosphate_and_(aa)
    sum
  end

end # class DomainRnaInterface


class ChainInterface < Interface

  belongs_to :chain

  has_many :residues, :class_name => "Residue", :foreign_key => "chain_interface_id"

end


class ChainDnaInterface < ChainInterface
end


class ChainRnaInterface < ChainInterface
end
