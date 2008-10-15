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

#  before_save :update_asa,
#              :update_polarity,
#              :update_singlet_propensities,
#              :update_sse_propensities

  delegate  :pdb_code, :r_value, :r_free, :sunid, :sccs, :sid, :description, :resolution,
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

  def singlet_propensity_of(res)
    result = ((delta_asa_of_residue(res) / delta_asa) /
              (domain.unbound_asa_of_residue(res) / domain.unbound_asa))
    result.to_f.nan? ? 1 : result
  end
  memoize :singlet_propensity_of

  def sse_propensity_of(sse)
    result = ((delta_asa_of_sse(sse) / delta_asa) /
              (domain.unbound_asa_of_sse(sse) / domain.unbound_asa))
    result.to_f.nan? ? 1 : result
  end
  memoize :sse_propensity_of

  def frequency_of_hbond_between(aa, na)
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
  memoize :frequency_of_hbond_between

  def frequency_of_whbond_between(aa, na)
    sum = 0
    whbonds.each do |whbond|
      sum += 1 if (whbond.atom.residue.residue_name == aa &&
                   whbond.whbonding_atom.residue.residue_name == na &&
                   !NucleicAcids::Atoms::SUGAR.include?(whbond.whbonding_atom) &&
                   !NucleicAcids::Atoms::PHOSPHATE.include?(whbond.whbonding_atom))
    end
    sum
  end
  memoize :frequency_of_whbond_between

  def frequency_of_vdw_contact_between(aa, na)
    sum = 0
    vdw_contacts.each do |vdw_contact|
      sum += 1 if (vdw_contact.atom.residue.residue_name == aa &&
                   vdw_contact.vdw_contacting_atom.residue.residue_name == na &&
                   !NucleicAcids::Atoms::SUGAR.include?(vdw_contact.vdw_contacting_atom) &&
                   !NucleicAcids::Atoms::PHOSPHATE.include?(vdw_contact.vdw_contacting_atom))
    end
    sum - frequency_of_hbond_between(aa, na)
  end
  memoize :frequency_of_vdw_contact_between

  def frequency_of_hbond_between_sugar_and_(aa)
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
  memoize :frequency_of_hbond_between_sugar_and_

  def frequency_of_whbond_between_sugar_and_(aa)
    sum = 0
    whbonds.each do |whbond|
      sum += 1 if (whbond.atom.residue.residue_name == aa &&
                   NucleicAcids::Atoms::SUGAR.include?(whbond.whbonding_atom.atom_name))
    end
    sum
  end
  memoize :frequency_of_whbond_between_sugar_and_

  def frequency_of_vdw_contact_between_sugar_and_(aa)
    sum = 0
    vdw_contacts.each do |vdw_contact|
      sum += 1 if (vdw_contact.atom.residue.residue_name == aa &&
                   NucleicAcids::Atoms::SUGAR.include?(vdw_contact.vdw_contacting_atom.atom_name))
    end
    sum
  end
  memoize :frequency_of_vdw_contact_between_sugar_and_

  def frequency_of_hbond_between_phosphate_and_(aa)
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
  memoize :frequency_of_hbond_between_phosphate_and_

  def frequency_of_whbond_between_phosphate_and_(aa)
    sum = 0
    whbonds.each do |whbond|
      sum += 1 if (whbond.atom.residue.residue_name == aa &&
                   NucleicAcids::Atoms::PHOSPHATE.include?(whbond.whbonding_atom.atom_name))
    end
    sum
  end
  memoize :frequency_of_whbond_between_phosphate_and_

  def frequency_of_vdw_contact_between_phosphate_and_(aa)
    sum = 0
    vdw_contacts.each do |vdw_contact|
      sum += 1 if (vdw_contact.atom.residue.residue_name == aa &&
                   NucleicAcids::Atoms::PHOSPHATE.include?(vdw_contact.vdw_contacting_atom.atom_name))
    end
    sum
  end
  memoize :frequency_of_vdw_contact_between_phosphate_and_

  def frequency_of_hbond_between_amino_acids_and_(na)
    AminoAcids::Residues::STANDARD.inject(0) { |s, r| s + frequency_of_hbond_between(r, na) }
  end
  memoize :frequency_of_hbond_between_amino_acids_and_

  def frequency_of_whbond_between_amino_acids_and_(na)
    AminoAcids::Residues::STANDARD.inject(0) { |s, r| s + frequency_of_whbond_between(r, na) }
  end
  memoize :frequency_of_whbond_between_amino_acids_and_

  def frequency_of_vdw_contact_between_amino_acids_and_(na)
    AminoAcids::Residues::STANDARD.inject(0) { |s, r| s + frequency_of_vdw_contact_between(r, na) }
  end
  memoize :frequency_of_vdw_contact_between_amino_acids_and_


  protected

  # Callbacks
  def update_asa
    self.asa = delta_asa
  end

  def update_polarity
    begin
      result = delta_asa_polar / delta_asa
    rescue ZeroDivisionError
      result = 1
    ensure
      result = result.to_f.nan? ? 1 : result
    end
    self.polarity = result
  end

  def update_singlet_propensities
    AminoAcids::Residues::STANDARD.each do |aa|
      send("singlet_propensity_of_#{aa.downcase}=", singlet_propensity_of(aa))
    end
  end

  def update_sse_propensities
    Sses::ALL.each do |sse|
      send("sse_propensity_of_#{sse.downcase}=", sse_propensity_of(sse))
    end
  end

  %w(hbond whbond vdw_contact).each do |intact|

    AminoAcids::Residues::STANDARD.each do |aa|
      class_eval <<-END
        before_save :update_frequency_of_#{intact}_between_#{aa.downcase}_and_nucleic_acids

        def update_frequency_of_#{intact}_between_#{aa.downcase}_and_nucleic_acids
          self.frequency_of_#{intact}_between_#{aa.downcase}_and_nucleic_acids =
          frequency_of_#{intact}_between_nucleic_acids_and_("#{aa}")
        end
      END
    end

    %w(sugar phosphate).each do |moiety|
      class_eval <<-END
        before_save :update_frequency_of_#{intact}_between_amino_acids_and_#{moiety}

        def update_frequency_of_#{intact}_between_amino_acids_and_#{moiety}
          self.frequency_of_#{intact}_between_amino_acids_and_#{moiety} =
            AminoAcids::Residues::STANDARD.inject(0) { |sum, aa|
              sum + frequency_of_#{intact}_between_#{moiety}_and_(aa)
            }
        end
      END

      AminoAcids::Residues::STANDARD.each do |aa|
        class_eval <<-END
          before_save :update_frequency_of_#{intact}_between_#{aa.downcase}_and_#{moiety}

          def update_frequency_of_#{intact}_between_#{aa.downcase}_and_#{moiety}
            self.frequency_of_#{intact}_between_#{aa.downcase}_and_#{moiety} =
            frequency_of_#{intact}_between_#{moiety}_and_("#{aa}")
          end
        END
      end
    end
  end
end # class DomainInterface


class DomainDnaInterface < DomainInterface

#  %w(hbond whbond vdw_contact).each do |intact|
#
#    NucleicAcids::Dna::Residues::STANDARD.each do |dna|
#      class_eval <<-END
#        before_save :update_frequency_of_#{intact}_between_amino_acids_and_#{dna.downcase}
#
#        def update_frequency_of_#{intact}_between_amino_acids_and_#{dna.downcase}
#          self.frequency_of_#{intact}_between_amino_acids_and_#{dna.downcase} =
#          frequency_of_#{intact}_between_amino_acids_and_("#{dna}")
#        end
#      END
#
#      AminoAcids::Residues::STANDARD.each do |aa|
#        class_eval <<-END
#          before_save :update_frequency_of_#{intact}_between_#{aa.downcase}_and_#{dna.downcase}
#
#          def update_frequency_of_#{intact}_between_#{aa.downcase}_and_#{dna.downcase}
#            self.frequency_of_#{intact}_between_#{aa.downcase}_and_#{dna.downcase} =
#            frequency_of_#{intact}_between("#{aa}", "#{dna}")
#          end
#        END
#      end
#    end
#
#    class_eval <<-END
#      def frequency_of_#{intact}_between_nucleic_acids_and_(aa)
#        sum = 0
#        NucleicAcids::Dna::Residues::STANDARD.each do |dna|
#          sum += frequency_of_#{intact}_between(aa, dna)
#        end
#        sum += frequency_of_hbond_between_sugar_and_(aa)
#        sum += frequency_of_hbond_between_phosphate_and_(aa)
#      end
#    END
#  end
end # class DomainDnaInterface


class DomainRnaInterface < DomainInterface

#  %w(hbond whbond vdw_contact).each do |intact|
#    NucleicAcids::Rna::Residues::STANDARD.each do |rna|
#      class_eval <<-END
#        before_save :update_frequency_of_#{intact}_between_amino_acids_and_#{rna.downcase}
#
#        def update_frequency_of_#{intact}_between_amino_acids_and_#{rna.downcase}
#          self.frequency_of_#{intact}_between_amino_acids_and_#{rna.downcase} =
#          frequency_of_#{intact}_between_amino_acids_and_("#{rna}")
#        end
#      END
#
#      AminoAcids::Residues::STANDARD.each do |aa|
#        class_eval <<-END
#          before_save :update_frequency_of_#{intact}_between_#{aa.downcase}_and_#{rna.downcase}
#
#          def update_frequency_of_#{intact}_between_#{aa.downcase}_and_#{rna.downcase}
#            self.frequency_of_#{intact}_between_#{aa.downcase}_and_#{rna.downcase} =
#            frequency_of_#{intact}_between("#{aa}", "#{rna}")
#          end
#        END
#      end
#    end
#
#    class_eval <<-END
#      def frequency_of_#{intact}_between_nucleic_acids_and_(aa)
#        sum = 0
#        NucleicAcids::Rna::Residues::STANDARD.each do |rna|
#          sum += frequency_of_#{intact}_between(aa, rna)
#        end
#        sum += frequency_of_hbond_between_sugar_and_(aa)
#        sum += frequency_of_hbond_between_phosphate_and_(aa)
#      end
#    END
#  end

end # class DomainRnaInterface


class ChainInterface < Interface

  belongs_to :chain
end


class ChainDnaInterface < ChainInterface
end


class ChainRnaInterface < ChainInterface
end
