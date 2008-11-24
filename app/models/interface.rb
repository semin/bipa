class Interface < ActiveRecord::Base

  include Bipa::Constants
  include Bipa::ComposedOfResidues

end

class DomainInterface < Interface

  belongs_to  :domain,
              :class_name   => "ScopDomain",
              :foreign_key  => 'scop_id'

  has_many  :residues,
            :class_name   => "Residue",
            :foreign_key  => "domain_interface_id"

  has_many  :chains,
            :through      => :residues,
            :uniq         => true

  has_many  :atoms,
            :through      => :residues

  delegate  :pdb_code,
            :r_value,
            :r_free,
            :sunid,
            :sccs,
            :sid,
            :description,
            :resolution,
            :to => :domain

  named_scope :max_resolution, lambda { |res|
    {
      :include    => :domain,
      :conditions => ["scops.resolution < ?", res.to_f]
    }
  }

  def na_type
    "Protein-" + case self[:type]
    when /Dna/i then "DNA"
    when /Rna/i then "RNA"
    else; "Unknown"
    end
  end

  def calculate_singlet_propensity_of(res)
    result = ((delta_asa_of_residue(res) / delta_asa) /
              (domain.unbound_asa_of_residue(res) / domain.unbound_asa))
    result.to_f.nan? ? 1 : result
  end
  #memoize :calculate_singlet_propensity_of

  def calculate_sse_propensity_of(sse)
    result = ((delta_asa_of_sse(sse) / delta_asa) /
              (domain.unbound_asa_of_sse(sse) / domain.unbound_asa))
    result.to_f.nan? ? 1 : result
  end
  #memoize :calculate_sse_propensity_of

  def calculate_frequency_of_hbond_between(aa, na)
    sum = 0
    hbonds_as_donor.each do |hbond|
      sum += 1 if (hbond.donor.residue.residue_name == aa &&
                   hbond.acceptor.residue.residue_name == na &&
                   !NucleicAcids::Atoms::SUGAR.include?(hbond.acceptor.atom_name) &&
                   !NucleicAcids::Atoms::PHOSPHATE.include?(hbond.acceptor.atom_name))
    end
    hbonds_as_acceptor.each do |hbond|
      sum += 1 if (hbond.acceptor.residue.residue_name == aa &&
                   hbond.donor.residue.residue_name == na &&
                   !NucleicAcids::Atoms::SUGAR.include?(hbond.donor.atom_name) &&
                   !NucleicAcids::Atoms::PHOSPHATE.include?(hbond.donor.atom_name))
    end
    sum
  end
  #memoize :calculate_frequency_of_hbond_between

  def calculate_frequency_of_whbond_between(aa, na)
    sum = 0
    whbonds.each do |whbond|
      sum += 1 if (whbond.atom.residue.residue_name == aa &&
                   whbond.whbonding_atom.residue.residue_name == na &&
                   !NucleicAcids::Atoms::SUGAR.include?(whbond.whbonding_atom) &&
                   !NucleicAcids::Atoms::PHOSPHATE.include?(whbond.whbonding_atom))
    end
    sum
  end
  #memoize :calculate_frequency_of_whbond_between

  def calculate_frequency_of_vdw_contact_between(aa, na)
    sum = 0
    vdw_contacts.each do |vdw_contact|
      sum += 1 if (vdw_contact.atom.residue.residue_name == aa &&
                   vdw_contact.vdw_contacting_atom.residue.residue_name == na &&
                   !NucleicAcids::Atoms::SUGAR.include?(vdw_contact.vdw_contacting_atom) &&
                   !NucleicAcids::Atoms::PHOSPHATE.include?(vdw_contact.vdw_contacting_atom))
    end
    sum - calculate_frequency_of_hbond_between(aa, na)
  end
  #memoize :calculate_frequency_of_vdw_contact_between

  def calculate_frequency_of_hbond_between_sugar_and_(aa)
    sum = 0
    hbonds_as_donor.each do |hbond|
      sum += 1 if (hbond.donor.residue.residue_name == aa &&
                   NucleicAcids::Atoms::SUGAR.include?(hbond.acceptor.atom_name))
    end
    hbonds_as_acceptor.each do |hbond|
      sum += 1 if (hbond.acceptor.residue.residue_name == aa &&
                   NucleicAcids::Atoms::SUGAR.include?(hbond.donor.atom_name))
    end
    sum
  end
  #memoize :calculate_frequency_of_hbond_between_sugar_and_

  def calculate_frequency_of_whbond_between_sugar_and_(aa)
    sum = 0
    whbonds.each do |whbond|
      sum += 1 if (whbond.atom.residue.residue_name == aa &&
                   NucleicAcids::Atoms::SUGAR.include?(whbond.whbonding_atom.atom_name))
    end
    sum
  end
  #memoize :calculate_frequency_of_whbond_between_sugar_and_

  def calculate_frequency_of_vdw_contact_between_sugar_and_(aa)
    sum = 0
    vdw_contacts.each do |vdw_contact|
      sum += 1 if (vdw_contact.atom.residue.residue_name == aa &&
                   NucleicAcids::Atoms::SUGAR.include?(vdw_contact.vdw_contacting_atom.atom_name))
    end
    sum
  end
  #memoize :calculate_frequency_of_vdw_contact_between_sugar_and_

  def calculate_frequency_of_hbond_between_phosphate_and_(aa)
    sum = 0
    hbonds_as_donor.each do |hbond|
      sum += 1 if (hbond.donor.residue.residue_name == aa &&
                   NucleicAcids::Atoms::PHOSPHATE.include?(hbond.acceptor.atom_name))
    end
    hbonds_as_acceptor.each do |hbond|
      sum += 1 if (hbond.acceptor.residue.residue_name == aa &&
                   NucleicAcids::Atoms::PHOSPHATE.include?(hbond.donor.atom_name))
    end
    sum
  end
  #memoize :calculate_frequency_of_hbond_between_phosphate_and_

  def calculate_frequency_of_whbond_between_phosphate_and_(aa)
    sum = 0
    whbonds.each do |whbond|
      sum += 1 if (whbond.atom.residue.residue_name == aa &&
                   NucleicAcids::Atoms::PHOSPHATE.include?(whbond.whbonding_atom.atom_name))
    end
    sum
  end
  #memoize :calculate_frequency_of_whbond_between_phosphate_and_

  def calculate_frequency_of_vdw_contact_between_phosphate_and_(aa)
    sum = 0
    vdw_contacts.each do |vdw_contact|
      sum += 1 if (vdw_contact.atom.residue.residue_name == aa &&
                   NucleicAcids::Atoms::PHOSPHATE.include?(vdw_contact.vdw_contacting_atom.atom_name))
    end
    sum
  end
  #memoize :calculate_frequency_of_vdw_contact_between_phosphate_and_

  def calculate_frequency_of_hbond_between_amino_acids_and_(na)
    AminoAcids::Residues::STANDARD.inject(0) { |s, r| s + calculate_frequency_of_hbond_between(r, na) }
  end
  #memoize :calculate_frequency_of_hbond_between_amino_acids_and_

  def calculate_frequency_of_whbond_between_amino_acids_and_(na)
    AminoAcids::Residues::STANDARD.inject(0) { |s, r| s + calculate_frequency_of_whbond_between(r, na) }
  end
  #memoize :calculate_frequency_of_whbond_between_amino_acids_and_

  def calculate_frequency_of_vdw_contact_between_amino_acids_and_(na)
    AminoAcids::Residues::STANDARD.inject(0) { |s, r| s + calculate_frequency_of_vdw_contact_between(r, na) }
  end
  #memoize :calculate_frequency_of_vdw_contact_between_amino_acids_and_


  def calculate_polarity
    begin
      result = delta_asa_polar / delta_asa
    rescue ZeroDivisionError
      result = 1
    ensure
      result = result.to_f.nan? ? 1 : result
    end
    result
  end
  #memoize :calculate_polarity
end # class DomainInterface


class DomainDnaInterface < DomainInterface

  %w(hbond whbond vdw_contact).each do |intact|
    class_eval <<-END
      def calculate_frequency_of_#{intact}_between_nucleic_acids_and_(aa)
        sum = 0
        NucleicAcids::Dna::Residues::STANDARD.each do |dna|
          sum += calculate_frequency_of_#{intact}_between(aa, dna)
        end
        sum += calculate_frequency_of_hbond_between_sugar_and_(aa)
        sum += calculate_frequency_of_hbond_between_phosphate_and_(aa)
      end
      #memoize :calculate_frequency_of_#{intact}_between_nucleic_acids_and_
    END
  end
end # class DomainDnaInterface


class DomainRnaInterface < DomainInterface

  %w(hbond whbond vdw_contact).each do |intact|
    class_eval <<-END
      def calculate_frequency_of_#{intact}_between_nucleic_acids_and_(aa)
        sum = 0
        NucleicAcids::Rna::Residues::STANDARD.each do |rna|
          sum += calculate_frequency_of_#{intact}_between(aa, rna)
        end
        sum += calculate_frequency_of_hbond_between_sugar_and_(aa)
        sum += calculate_frequency_of_hbond_between_phosphate_and_(aa)
      end
      #memoize :calculate_frequency_of_#{intact}_between_nucleic_acids_and_
    END
  end
end # class DomainRnaInterface


class ChainInterface < Interface

  belongs_to :chain
end


class ChainDnaInterface < ChainInterface
end


class ChainRnaInterface < ChainInterface
end
