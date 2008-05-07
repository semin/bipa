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
    
    should "return a correct justified residue name when sending #justified_residue_name" do
      residue = Residue.new(valid_residue_params(:residue_name => "DA"))
      
      assert_equal " DA", residue.justified_residue_name
    end
    
    should "return a correct justified residue code when sending #justified_residue_code" do
      residue = Residue.new(valid_residue_params(:residue_code => 1))
      assert_equal "0001", residue.justified_residue_code
    end
    
    
    context "with one or more surface atoms" do
      
      should "be true when sending #on_surface?" do
        residue       = Residue.new
        surface_atoms = stub(:size => 100)
        residue.stubs(:surface_atoms).returns(surface_atoms)
        
        assert residue.on_surface?
      end
    end
    
    
    context "losing bigger than 1 square angstrom when forming complex" do
      
      should "be true when sending #on_interface?" do
        residue         = Residue.new
        interface_atoms = stub(:size => 10)
        residue.stubs(:interface_atoms).returns(interface_atoms)
        
        assert residue.on_interface?
      end
    end
    
    context "with no surface atoms" do
      
      should "be true when sending #buried?" do
        residue       = Residue.new
        surface_atoms = stub(:size => 0)
        residue.stubs(:surface_atoms).returns(surface_atoms)
        
        assert residue.buried?
      end
    end


    context "with two atoms added" do

      setup do
        @residue = Residue.new
        @atom1 = Atom.create(valid_atom_params)
        @atom2 = Atom.create(valid_atom_params)
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
          @hbond          = Hbond.new
          @hbond.donor    = @atom1
          @hbond.acceptor = @atom2
          @hbond.save
        end
        
        should "have one hbonds_as_donor" do
          assert_equal 1, @residue.hbonds_as_donor.size
        end
        
        should "have one hbonds_as_acceptor" do
          assert_equal 1, @residue.hbonds_as_acceptor.size
        end
      end
      
      
      context "whbonding each other" do
        
        setup do
          @whbond                 = Whbond.new
          @whbond.atom            = @atom1
          @whbond.whbonding_atom  = @atom2
          @whbond.water_atom      = Atom.new(valid_atom_params(:atom_name => "HOH"))
          @whbond.save
        end
        
        should "have one whbond" do
          assert_equal 1, @residue.whbonds.size
        end
      end
    end
  end
end


class AaResidueTest < Test::Unit::TestCase
  
  should_belong_to  :domain

  should_belong_to  :domain_interface
  
  context "An AaResidue instance" do
    
    should "repond to #aa?, #na?, #dna?, #rna?, and #het? properly" do
      residue = AaResidue.new
      
      assert residue.aa?
      assert !residue.na?
      assert !residue.dna?
      assert !residue.rna?
      assert !residue.het?
    end
    
    should "have correct one letter code when #one_letter_code" do
      AminoAcids::Residues::STANDARD.each do |aa|
        standard_aa = AaResidue.new(valid_residue_params(:residue_name => aa))
        assert_equal AminoAcids::Residues::ONE_LETTER_CODE[aa], standard_aa.one_letter_code
      end
    end

    should "raise Error when it is non-standard amino acid when #one_letter_code" do
      non_standard_aa = AaResidue.new(valid_residue_params(:residue_name => "HEL"))
      assert_raise(RuntimeError) { non_standard_aa.one_letter_code }
    end
  end
end


class DnaResidueTest < Test::Unit::TestCase
  
  context "An DnaResidue instance" do
    
    should "repond to #aa?, #na?, #dna?, #rna?, and #het? properly" do
      residue = DnaResidue.new
      
      assert !residue.aa?
      assert residue.na?
      assert residue.dna?
      assert !residue.rna?
      assert !residue.het?
    end
  end
end


class RnaResidueTest < Test::Unit::TestCase
  
  context "An RnaResidue instance" do
    
    should "repond to #aa?, #na?, #dna?, #rna?, and #het? properly" do
      residue = RnaResidue.new
      
      assert !residue.aa?
      assert residue.na?
      assert !residue.dna?
      assert residue.rna?
      assert !residue.het?
    end
  end
end


class HetResidueTest < Test::Unit::TestCase
  
  context "An HetResidue instance" do
    
    should "repond to #aa?, #na?, #dna?, #rna?, and #het? properly" do
      residue = HetResidue.new
      
      assert !residue.aa?
      assert !residue.na?
      assert !residue.dna?
      assert !residue.rna?
      assert residue.het?
    end
  end
end
