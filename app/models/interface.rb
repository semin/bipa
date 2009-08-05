class Interface < ActiveRecord::Base

  include Bipa::Constants
  include Bipa::ComposedOfResidues

  has_many  :interface_similarities,
            :dependent  => :destroy

  has_many  :similar_interfaces,
            :through    => :interface_similarities

  named_scope :in_asa_range, lambda { |min_asa, max_asa|
    { :conditions => ["asa >= ? and asa <= ?", min_asa, max_asa] }
  }

  named_scope :in_polarity_range, lambda { |min_polarity, max_polarity|
    { :conditions => ["polarity >= ? and polarity <= ?", min_polarity, max_polarity] }
  }

  named_scope :in_residues_count_range, lambda { |min_residues_count, max_residues_count|
    { :conditions => ["residues_count >= ? and residues_count <= ?", min_residues_count, max_residues_count] }
  }

  named_scope :in_atoms_count_range, lambda { |min_atoms_count, max_atoms_count|
    { :conditions => ["atoms_count >= ? and atoms_count <= ?", min_atoms_count, max_atoms_count] }
  }

  named_scope :in_hbonds_count_range, lambda { |min_hbonds_count, max_hbonds_count|
    { :conditions => ["hbonds_count >= ? and hbonds_count <= ?", min_hbonds_count, max_hbonds_count] }
  }

  named_scope :in_whbonds_count_range, lambda { |min_whbonds_count, max_whbonds_count|
    { :conditions => ["whbonds_count >= ? and whbonds_count <= ?", min_whbonds_count, max_whbonds_count] }
  }

  named_scope :in_vdw_contacts_count_range, lambda { |min_vdw_contacts_count, max_vdw_contacts_count|
    { :conditions => ["vdw_contacts_count >= ? and vdw_contacts_count <= ?", min_vdw_contacts_count, max_vdw_contacts_count] }
  }

  acts_as_network :similar_interfaces_in_usr,
                  :through                  => :interface_similarities,
                  :foreign_key              => 'interface_id',
                  :association_foreign_key  => 'similar_interface_id'

  def self.usr_score_between(int1, int2)
    sim1 = InterfaceSimilarity.first(:conditions => { :interface_id => int1.id, :similar_interface_id => int2.id })
    sim2 = InterfaceSimilarity.first(:conditions => { :interface_id => int2.id, :similar_interface_id => int1.id })
    if sim1
      sim1.usr_score
    elsif sim2
      sim2.usr_score
    else
      nil
    end
  end

  def sorted_similar_interfaces_in_usr(min = nil)
    if min
      similar_interfaces_in_usr.sort_by { |i| self.class.usr_score_between(self, i) }.reverse[0..min-1]
    else
      similar_interfaces_in_usr.sort_by { |i| self.class.usr_score_between(self, i) }.reverse
    end
  end

  def interface_type
    (self[:type].match(/DNA/i) ? "DNA" : "RNA") + " interface"
  end

  def interface_to
    self[:type].match(/DNA/i) ? "DNA" : "RNA"
  end

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

  def calculate_asa
    residues.inject(0) { |s, r| s + r.delta_asa }
  end

  def calculate_percent_asa
    100.0 * self[:asa] / domain.unbound_asa rescue 0
  end

  def calculate_residue_percentage_of(res)
    result = 100.0 * delta_asa_of_residue(res) / delta_asa rescue 0
  end

  def calculate_residue_propensity_of(res)
    result = ((delta_asa_of_residue(res) / delta_asa) /
              (domain.unbound_asa_of_residue(res) / domain.unbound_asa))
    result.to_f.nan? ? 1.0 : result
  end

  def calculate_sse_percentage_of(sse)
    result = 100.0 * delta_asa_of_sse(sse) / delta_asa rescue 0
  end

  def calculate_sse_propensity_of(sse)
    result = ((delta_asa_of_sse(sse) / delta_asa) /
              (domain.unbound_asa_of_sse(sse) / domain.unbound_asa))
    result.to_f.nan? ? 1.0 : result
  end

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

  def calculate_frequency_of_whbond_between_sugar_and_(aa)
    sum = 0
    whbonds.each do |whbond|
      sum += 1 if (whbond.atom.residue.residue_name == aa &&
                   NucleicAcids::Atoms::SUGAR.include?(whbond.whbonding_atom.atom_name))
    end
    sum
  end

  def calculate_frequency_of_vdw_contact_between_sugar_and_(aa)
    sum = 0
    vdw_contacts.each do |vdw_contact|
      sum += 1 if (vdw_contact.atom.residue.residue_name == aa &&
                   NucleicAcids::Atoms::SUGAR.include?(vdw_contact.vdw_contacting_atom.atom_name))
    end
    sum
  end

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

  def calculate_frequency_of_whbond_between_phosphate_and_(aa)
    sum = 0
    whbonds.each do |whbond|
      sum += 1 if (whbond.atom.residue.residue_name == aa &&
                   NucleicAcids::Atoms::PHOSPHATE.include?(whbond.whbonding_atom.atom_name))
    end
    sum
  end

  def calculate_frequency_of_vdw_contact_between_phosphate_and_(aa)
    sum = 0
    vdw_contacts.each do |vdw_contact|
      sum += 1 if (vdw_contact.atom.residue.residue_name == aa &&
                   NucleicAcids::Atoms::PHOSPHATE.include?(vdw_contact.vdw_contacting_atom.atom_name))
    end
    sum
  end

  def calculate_frequency_of_hbond_between_amino_acids_and_(na)
    AminoAcids::Residues::STANDARD.inject(0) { |s, r| s + calculate_frequency_of_hbond_between(r, na) }
  end

  def calculate_frequency_of_whbond_between_amino_acids_and_(na)
    AminoAcids::Residues::STANDARD.inject(0) { |s, r| s + calculate_frequency_of_whbond_between(r, na) }
  end

  def calculate_frequency_of_vdw_contact_between_amino_acids_and_(na)
    AminoAcids::Residues::STANDARD.inject(0) { |s, r| s + calculate_frequency_of_vdw_contact_between(r, na) }
  end

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

  def residue_percentage_google_chart_url
    data = AminoAcids::Residues::STANDARD.map { |r| calculate_residue_percentage_of(r) }
    Gchart.bar(:size              => '600x100',
               :title             => 'Residue Percentage (%)',
               :data              => data,
               :axis_with_labels  => 'x,y',
               :axis_labels       => [AminoAcids::Residues::STANDARD.join('|'), [0, data.max.round]])
  end

  def residue_propensity_google_chart_url
    data = AminoAcids::Residues::STANDARD.map { |r| calculate_residue_propensity_of(r) }
    Gchart.bar(:size              => '600x100',
               :title             => 'Residue Propensity',
               :data              => data,
               :axis_with_labels  => 'x,y',
               :axis_labels       => [AminoAcids::Residues::STANDARD.join('|'), [0, data.max.round]])
  end

  def sse_percentage_google_chart_url
    data = Sses::ALL.map { |s| calculate_sse_percentage_of(s) }
    Gchart.bar(:size              => '250x100',
               :title             => 'SSE Percentage (%)',
               :data              => data,
               :axis_with_labels  => 'x,y',
               :axis_labels       => [Sses::ALL.join('|'), [0, data.max.round]])
  end

  def sse_propensity_google_chart_url
    data = Sses::ALL.map { |s| calculate_sse_propensity_of(s) }
    Gchart.bar(:size              => '250x100',
               :title             => 'SSE Propensity',
               :data              => data,
               :axis_with_labels  => 'x,y',
               :axis_labels       => [Sses::ALL.join('|'), [0, data.max.round]])
  end

  def residue_percentage_vector
    NVector[*AminoAcids::Residues::STANDARD.map { |r| self[:"residue_percentage_of_#{r.downcase}"] }]
  end

  def residue_propensity_vector
    NVector[*AminoAcids::Residues::STANDARD.map { |r| self[:"residue_propensity_of_#{r.downcase}"] }]
  end

  def sse_percentage_vector
    NVector[*Sses::ALL.map { |s| self[:"sse_percentage_of_#{s.downcase}"] }]
  end

  def sse_propensity_vector
    NVector[*Sses::ALL.map { |s| self[:"sse_propensity_of_#{s.downcase}"] }]
  end
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
