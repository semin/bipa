require File.dirname(__FILE__) + '/../test_helper'

class InterfaceTest < Test::Unit::TestCase
  
  context "An Interface instance" do
    
    should "respond to 'atoms' method" do
      i = Interface.new
      assert i.respond_to?(:atoms)
    end
    
    should "respond to 'residues' method" do
      i = Interface.new
      assert i.respond_to?(:residues)
    end
    
    should "respond to #surface_residues" do
      i = Interface.new
      assert i.respond_to?(:surface_residues)
    end
    
    should "respond to #buried_residues" do
      i = Interface.new
      assert i.respond_to?(:buried_residues)
    end
    
    should "respond to #interface_residues" do
      i = Interface.new
      assert i.respond_to?(:interface_residues)
    end
    
    should "respond to #exclusive_surface_residues" do
      i = Interface.new
      assert i.respond_to?(:exclusive_surface_residues)
    end
    
    should "respond to #dna_binding_residues" do
      i = Interface.new
      assert i.respond_to?(:dna_binding_residues)
    end
    
    should "respond to #rna_binding_residues" do
      i = Interface.new
      assert i.respond_to?(:rna_binding_residues)
    end
    
    should "respond to #dna_binding_interface_residues" do
      i = Interface.new
      assert i.respond_to?(:dna_binding_interface_residues)
    end
    
    should "respond to #rna_binding_interface_residues" do
      i = Interface.new
      assert i.respond_to?(:rna_binding_interface_residues)
    end
    
    %w(unbound bound delta).each do |stat|
      should "respond to #{stat}_asa_of_residue" do
        i = Interface.new
        assert i.respond_to?(:"#{stat}_asa_of_residue")
      end
      
      should "respond to #{stat}_asa_of_sse" do
        i = Interface.new
        assert i.respond_to?(:"#{stat}_asa_of_sse")
      end
    end
  end
end

class DomainInterfaceTest < Test::Unit::TestCase

  #include Bipa::NucleicAcidBinding

  should_belong_to  :domain

  # before_save :update_asa,
  #             :update_polarity,
  #             :update_singlet_propensities,
  #             :update_sse_propensities
  # 
  # def singlet_propensity_of(res)
  #   result = ((delta_asa_of_residue(res) / delta_asa) /
  #             (domain.unbound_asa_of_residue(res) / domain.unbound_asa))
  #   result.to_f.nan? ? 1 : result
  # end
  # 
  # def sse_propensity_of(sse)
  #   result = ((delta_asa_of_sse(sse) / delta_asa) /
  #             (domain.unbound_asa_of_sse(sse) / domain.unbound_asa))
  #   result.to_f.nan? ? 1 : result
  # end
  # 
  # def frequency_of_hbond_between(aa, na)
  #   sum = 0
  #   hbonds_as_donor.each do |hbond|
  #     sum += 1 if (hbond.donor.residue.residue_name == aa &&
  #                  hbond.acceptor.residue.residue_name == na &&
  #                  !NucleicAcids::Atoms::SUGAR.include?(hbond.acceptor.atom_name) &&
  #                  !NucleicAcids::Atoms::PHOSPHATE.include?(hbond.acceptor.atom_name))
  #   end
  #   hbonds_as_acceptor.each do |hbond|
  #     sum += 1 if (hbond.acceptor.residue.residue_name == aa &&
  #                  hbond.donor.residue.residue_name == na &&
  #                  !NucleicAcids::Atoms::SUGAR.include?(hbond.donor.atom_name) &&
  #                  !NucleicAcids::Atoms::PHOSPHATE.include?(hbond.donor.atom_name))
  #   end
  #   sum
  # end
  # 
  # def frequency_of_whbond_between(aa, na)
  #   sum = 0
  #   whbonds.each do |whbond|
  #     sum += 1 if (whbond.atom.residue.residue_name == aa &&
  #                  whbond.whbonding_atom.residue.residue_name == na &&
  #                  !NucleicAcids::Atoms::SUGAR.include?(whbond.whbonding_atom) &&
  #                  !NucleicAcids::Atoms::PHOSPHATE.include?(whbond.whbonding_atom))
  #   end
  #   sum
  # end
  # 
  # def frequency_of_contact_between(aa, na)
  #   sum = 0
  #   contacts.each do |contact|
  #     sum += 1 if (contact.atom.residue.residue_name == aa &&
  #                  contact.contacting_atom.residue.residue_name == na &&
  #                  !NucleicAcids::Atoms::SUGAR.include?(contact.contacting_atom) &&
  #                  !NucleicAcids::Atoms::PHOSPHATE.include?(contact.contacting_atom))
  #   end
  #   sum - frequency_of_hbond_between(aa, na)
  # end
  # 
  # def frequency_of_hbond_between_sugar_and_(aa)
  #   sum = 0
  #   hbonds_as_donor.each do |hbond|
  #     sum += 1 if (hbond.donor.residue.residue_name == aa &&
  #                  NucleicAcids::Atoms::SUGAR.include?(hbond.acceptor.atom_name))
  #   end
  #   hbonds_as_acceptor.each do |hbond|
  #     sum += 1 if (hbond.acceptor.residue.residue_name == aa &&
  #                  NucleicAcids::Atoms::SUGAR.include?(hbond.donor.atom_name))
  #   end
  #   sum
  # end
  # 
  # def frequency_of_whbond_between_sugar_and_(aa)
  #   sum = 0
  #   whbonds.each do |whbond|
  #     sum += 1 if (whbond.atom.residue.residue_name == aa &&
  #                  NucleicAcids::Atoms::SUGAR.include?(whbond.whbonding_atom.atom_name))
  #   end
  #   sum
  # end
  # 
  # def frequency_of_contact_between_sugar_and_(aa)
  #   sum = 0
  #   contacts.each do |contact|
  #     sum += 1 if (contact.atom.residue.residue_name == aa &&
  #                  NucleicAcids::Atoms::SUGAR.include?(contact.contacting_atom.atom_name))
  #   end
  #   sum
  # end
  # 
  # def frequency_of_hbond_between_phosphate_and_(aa)
  #   sum = 0
  #   hbonds_as_donor.each do |hbond|
  #     sum += 1 if (hbond.donor.residue.residue_name == aa &&
  #                  NucleicAcids::Atoms::PHOSPHATE.include?(hbond.acceptor.atom_name))
  #   end
  #   hbonds_as_acceptor.each do |hbond|
  #     sum += 1 if (hbond.acceptor.residue.residue_name == aa &&
  #                  NucleicAcids::Atoms::PHOSPHATE.include?(hbond.donor.atom_name))
  #   end
  #   sum
  # end
  # 
  # def frequency_of_whbond_between_phosphate_and_(aa)
  #   sum = 0
  #   whbonds.each do |whbond|
  #     sum += 1 if (whbond.atom.residue.residue_name == aa &&
  #                  NucleicAcids::Atoms::PHOSPHATE.include?(whbond.whbonding_atom.atom_name))
  #   end
  #   sum
  # end
  # 
  # def frequency_of_contact_between_phosphate_and_(aa)
  #   sum = 0
  #   contacts.each do |contact|
  #     sum += 1 if (contact.atom.residue.residue_name == aa &&
  #                  NucleicAcids::Atoms::PHOSPHATE.include?(contact.contacting_atom.atom_name))
  #   end
  #   sum
  # end
  # 
  # def frequency_of_hbond_between_amino_acids_and_(na)
  #   AminoAcids::Residues::STANDARD.inject(0) { |s, r| s + frequency_of_hbond_between(r, na) }
  # end
  # 
  # def frequency_of_whbond_between_amino_acids_and_(na)
  #   AminoAcids::Residues::STANDARD.inject(0) { |s, r| s + frequency_of_whbond_between(r, na) }
  # end
  # 
  # def frequency_of_contact_between_amino_acids_and_(na)
  #   AminoAcids::Residues::STANDARD.inject(0) { |s, r| s + frequency_of_contact_between(r, na) }
  # end
  # 
  # 
  # protected
  # 
  # # Callbacks
  # def update_asa
  #   self.asa = delta_asa
  # end
  # 
  # def update_polarity
  #   begin
  #     result = delta_asa_polar / delta_asa
  #   rescue ZeroDivisionError
  #     result = 1
  #   ensure
  #     result = result.to_f.nan? ? 1 : result
  #   end
  #   self.polarity = result
  # end
  # 
  # def update_singlet_propensities
  #   AminoAcids::Residues::STANDARD.each do |aa|
  #     send("singlet_propensity_of_#{aa.downcase}=", singlet_propensity_of(aa))
  #   end
  # end
  # 
  # def update_sse_propensities
  #   Dssp::SSES.each do |sse|
  #     send("sse_propensity_of_#{sse.downcase}=", sse_propensity_of(sse))
  #   end
  # end
  # 
  # %w(hbond whbond contact).each do |intact|
  # 
  #   AminoAcids::Residues::STANDARD.each do |aa|
  # 
  #     class_eval <<-END
  #       before_save :update_frequency_of_#{intact}_between_#{aa.downcase}_and_nucleic_acids
  # 
  #       def update_frequency_of_#{intact}_between_#{aa.downcase}_and_nucleic_acids
  #         self.frequency_of_#{intact}_between_#{aa.downcase}_and_nucleic_acids =
  #         frequency_of_#{intact}_between_nucleic_acids_and_("#{aa}")
  #       end
  #     END
  #   end
  # 
  #   %w(sugar phosphate).each do |moiety|
  # 
  #     class_eval <<-END
  #       before_save :update_frequency_of_#{intact}_between_amino_acids_and_#{moiety}
  # 
  #       def update_frequency_of_#{intact}_between_amino_acids_and_#{moiety}
  #         self.frequency_of_#{intact}_between_amino_acids_and_#{moiety} =
  #           AminoAcids::Residues::STANDARD.inject(0) { |sum, aa|
  #             sum + frequency_of_#{intact}_between_#{moiety}_and_(aa)
  #           }
  #       end
  #     END
  # 
  #     AminoAcids::Residues::STANDARD.each do |aa|
  # 
  #       class_eval <<-END
  #         before_save :update_frequency_of_#{intact}_between_#{aa.downcase}_and_#{moiety}
  # 
  #         def update_frequency_of_#{intact}_between_#{aa.downcase}_and_#{moiety}
  #           self.frequency_of_#{intact}_between_#{aa.downcase}_and_#{moiety} =
  #           frequency_of_#{intact}_between_#{moiety}_and_("#{aa}")
  #         end
  #       END
  #     end
  #   end
  # end
end # class DomainInterfaceTest