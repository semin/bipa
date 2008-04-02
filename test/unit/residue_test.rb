require File.dirname(__FILE__) + '/../test_helper'

class ResidueTest < Test::Unit::TestCase
  
  should_belong_to  :chain

  should_belong_to  :chain_interface

  should_have_many  :atoms

  should_have_many  :contacts,
                    :through => :atoms

  # should_have_many  :contacting_atoms,
  #                   :through => :contacts

  should_have_many  :whbonds,
                    :through => :atoms

  # should_have_many  :whbonding_atoms,
  #                   :through => :whbonds

  should_have_many  :hbonds_as_donor,
                    :through => :atoms

  should_have_many  :hbonds_as_acceptor,
                    :through => :atoms

  # should_have_many  :hbonding_donors,
  #                   :through => :hbonds_as_acceptor
  # 
  # should_have_many  :hbonding_acceptors,
  #                   :through => :hbonds_as_donor
                    
  
  context "A Residue instance" do
    
    setup do
      @residue = Residue.new(valid_residue_params)
    end
    
    should "properly saved" do
      assert @residue.save
    end

    context "with two atoms added" do

      setup do
        @atom1 = Atom.new(valid_atom_params)
        @atom2 = Atom.new(valid_atom_params)
        @residue.atoms << @atom1
        @residue.atoms << @atom2
        @residue.save
      end
      
      should "have two atoms" do
        assert_equal 2, @residue.atoms.size
      end

      should "include every atom" do
        assert @residue.atoms.include?(@atom1)
        assert @residue.atoms.include?(@atom2)
      end
      
      
      context "contacting each other" do
      
        setup do
          @contact                  = Contact.new
          @contact.atom             = @atom1
          @contact.contacting_atom  = @atom2
          @contact.distance         = @atom1 - @atom2
          @contact.save
        end
        
        should "have one contact" do
          assert_equal 1, @residue.contacts.size
        end
      end
      
      context "hbonding each other" do
        
        setup do
          @hbond = Hbond.new
          @hbond.donor = @atom1
          @hbond.acceptor = @atom2
          @hbond.da_distance  = @atom1 - @atom2
          @hbond.save
        end
      end
    end
  end
end


class AaResidueTest < Test::Unit::TestCase
  
  should_belong_to  :domain

  should_belong_to  :domain_interface
  
  context "An AaResidue instance" do
    
    should "have correct one letter code when #one_letter_code" do
      AminoAcids::Residues::STANDARD.each do |aa|
        standard_aa = AaResidue.new(valid_residue_params(1, aa))
        assert_equal AminoAcids::Residues::ONE_LETTER_CODE[aa], standard_aa.one_letter_code
      end
    end
  
    should "raise Error when it is non-standard amino acid when #one_letter_code" do
      non_standard_aa = AaResidue.new(valid_residue_params(1, "HEL"))
      assert_raise(RuntimeError) { non_standard_aa.one_letter_code }
    end
  end
end
