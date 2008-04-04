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

  before_save :update_asa,
              :update_polarity,
              :update_singlet_propensities,
              :update_sse_propensities

  def singlet_propensity_of(res)
    begin
      result = ((delta_asa_of_residue(res) / delta_asa) /
                (domain.unbound_asa_of_residue(res) / domain.unbound_asa))
    rescue ZeroDivisionError
      result = 1
    ensure
      result.to_f.nan? ? 1 : result
    end
  end

  def sse_propensity_of(sse)
    begin
      result = ((delta_asa_of_sse(sse) / delta_asa) /
                (domain.unbound_asa_of_sse(sse) / domain.unbound_asa))
    rescue ZeroDivisionError
      result = 1
    ensure
      result.to_f.nan? ? 1 : result
    end
  end

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

  def frequency_of_contact_between(aa, na)
    sum = 0
    contacts.each do |contact|
      sum += 1 if (contact.atom.residue.residue_name == aa &&
                   contact.contacting_atom.residue.residue_name == na &&
                   !NucleicAcids::Atoms::SUGAR.include?(contact.contacting_atom) &&
                   !NucleicAcids::Atoms::PHOSPHATE.include?(contact.contacting_atom))
    end
    sum - frequency_of_hbond_between(aa, na)
  end

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

  def frequency_of_whbond_between_sugar_and_(aa)
    sum = 0
    whbonds.each do |whbond|
      sum += 1 if (whbond.atom.residue.residue_name == aa &&
                   NucleicAcids::Atoms::SUGAR.include?(whbond.whbonding_atom.atom_name))
    end
    sum
  end

  def frequency_of_contact_between_sugar_and_(aa)
    sum = 0
    contacts.each do |contact|
      sum += 1 if (contact.atom.residue.residue_name == aa &&
                   NucleicAcids::Atoms::SUGAR.include?(contact.contacting_atom.atom_name))
    end
    sum
  end

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

  def frequency_of_whbond_between_phosphate_and_(aa)
    sum = 0
    whbonds.each do |whbond|
      sum += 1 if (whbond.atom.residue.residue_name == aa &&
                   NucleicAcids::Atoms::PHOSPHATE.include?(whbond.whbonding_atom.atom_name))
    end
    sum
  end

  def frequency_of_contact_between_phosphate_and_(aa)
    sum = 0
    contacts.each do |contact|
      sum += 1 if (contact.atom.residue.residue_name == aa &&
                   NucleicAcids::Atoms::PHOSPHATE.include?(contact.contacting_atom.atom_name))
    end
    sum
  end

  def frequency_of_hbond_between_amino_acids_and_(na)
    AminoAcids::Residues::STANDARD.inject(0) { |s, r| s + frequency_of_hbond_between(r, na) }
  end

  def frequency_of_whbond_between_amino_acids_and_(na)
    AminoAcids::Residues::STANDARD.inject(0) { |s, r| s + frequency_of_whbond_between(r, na) }
  end

  def frequency_of_contact_between_amino_acids_and_(na)
    AminoAcids::Residues::STANDARD.inject(0) { |s, r| s + frequency_of_contact_between(r, na) }
  end


  protected

  # Callbacks
  def update_asa
    self.asa = delta_asa
  end

  def update_polarity
    begin
      self.polarity = delta_asa_polar / delta_asa
    rescue ZeroDivisionError
      self.polarity = 1
    end
  end

  def update_singlet_propensities
    AminoAcids::Residues::STANDARD.each do |aa|
      send("singlet_propensity_of_#{aa.downcase}=", singlet_propensity_of(aa))
    end
  end

  def update_sse_propensities
    Dssp::SSES.each do |sse|
      send("sse_propensity_of_#{sse.downcase}=", sse_propensity_of(sse))
    end
  end

  AminoAcids::Residues::STANDARD.each do |aa|

    %w(hbond whbond contact).each do |intact|

      %w(sugar phosphate).each do |moiety|

        class_eval <<-END
          before_save :update_frequency_of_#{intact}_between_#{aa.downcase}_and_#{moiety}

          def update_frequency_of_#{intact}_between_#{aa.downcase}_and_#{moiety}
            self.frequency_of_#{intact}_between_#{aa.downcase}_and_#{moiety} =
            frequency_of_#{intact}_between_#{moiety}_and_("#{aa}")
          end
        END
      end

      class_eval <<-END
        before_save :update_frequency_of_#{intact}_between_#{aa.downcase}_and_nucleic_acids

        def update_frequency_of_#{intact}_between_#{aa.downcase}_and_nucleic_acids
          self.frequency_of_#{intact}_between_#{aa.downcase}_and_nucleic_acids =
          frequency_of_#{intact}_between_nucleic_acids_and_("#{aa}")
        end
      END
    end
  end

end # class DomainInterface


class DomainDnaInterface < DomainInterface

  %w(hbond whbond contact).each do |intact|
    NucleicAcids::Dna::Residues::STANDARD.each do |dna|

      class_eval <<-END
        before_save :update_frequency_of_#{intact}_between_amino_acids_and_#{dna.downcase}

        def update_frequency_of_#{intact}_between_amino_acids_and_#{dna.downcase}
          self.frequency_of_#{intact}_between_amino_acids_and_#{dna.downcase} =
          frequency_of_#{intact}_between_amino_acids_and_("#{dna}")
        end
      END

      AminoAcids::Residues::STANDARD.each do |aa|

        class_eval <<-END
          before_save :update_frequency_of_#{intact}_between_#{aa.downcase}_and_#{dna.downcase}

          def update_frequency_of_#{intact}_between_#{aa.downcase}_and_#{dna.downcase}
            self.frequency_of_#{intact}_between_#{aa.downcase}_and_#{dna.downcase} =
            frequency_of_#{intact}_between("#{aa}", "#{dna}")
          end
        END
      end
    end

    class_eval <<-END
      def frequency_of_#{intact}_between_nucleic_acids_and_(aa)
        sum = 0
        NucleicAcids::Dna::Residues::STANDARD.each do |dna|
          sum += frequency_of_#{intact}_between(aa, dna)
        end
        sum += frequency_of_hbond_between_sugar_and_(aa)
        sum += frequency_of_hbond_between_phosphate_and_(aa)
      end
    END
  end
end # class DomainDnaInterface


class DomainRnaInterface < DomainInterface

  %w(hbond whbond contact).each do |intact|
    NucleicAcids::Rna::Residues::STANDARD.each do |rna|

      class_eval <<-END
        before_save :update_frequency_of_#{intact}_between_amino_acids_and_#{rna.downcase}

        def update_frequency_of_#{intact}_between_amino_acids_and_#{rna.downcase}
          self.frequency_of_#{intact}_between_amino_acids_and_#{rna.downcase} =
          frequency_of_#{intact}_between_amino_acids_and_("#{rna}")
        end
      END

      AminoAcids::Residues::STANDARD.each do |aa|

        class_eval <<-END
          before_save :update_frequency_of_#{intact}_between_#{aa.downcase}_and_#{rna.downcase}

          def update_frequency_of_#{intact}_between_#{aa.downcase}_and_#{rna.downcase}
            self.frequency_of_#{intact}_between_#{aa.downcase}_and_#{rna.downcase} =
            frequency_of_#{intact}_between("#{aa}", "#{rna}")
          end
        END
      end
    end

    class_eval <<-END
      def frequency_of_#{intact}_between_nucleic_acids_and_(aa)
        sum = 0
        NucleicAcids::Rna::Residues::STANDARD.each do |rna|
          sum += frequency_of_#{intact}_between(aa, rna)
        end
        sum += frequency_of_hbond_between_sugar_and_(aa)
        sum += frequency_of_hbond_between_phosphate_and_(aa)
      end
    END
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
