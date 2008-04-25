require File.dirname(__FILE__) + '/../test_helper'

class ChainTest < Test::Unit::TestCase
  
  should_belong_to  :model
  
  should_have_many  :residues
  
  should_have_many  :aa_residues
  
  should_have_many  :na_residues
  
  should_have_many  :dna_residues
  
  should_have_many  :rna_residues
  
  should_have_many  :het_residues
  
  should_have_many  :atoms,
                    :through => :residues
                    
  should_have_many  :aa_atoms,
                    :through => :aa_residues
                    
  should_have_many  :na_atoms,
                    :through => :na_residues
                    
  should_have_many  :dna_atoms,
                    :through => :dna_residues
  
  should_have_many  :rna_atoms,
                    :through => :rna_residues
                    
  should_have_many  :het_atoms,
                    :through => :het_residues
                    
  should_have_many  :sequences
end


class AaChainTest < ChainTest
  
  should_have_many  :dna_interfaces

  should_have_many  :rna_interfaces
  
  should_have_many  :domains,
                    :through => :aa_residues


  context "A AaChain instance" do
    
    context "with two amino acid residues having two atoms each" do
      
      setup do
        @aa_chain     = AaChain.create(valid_chain_params)
        @aa_residue1  = AaResidue.create(valid_residue_params(:residue_name => "ARG"))
        @aa_residue2  = AaResidue.create(valid_residue_params(:residue_name => "PHE"))
        @aa_atom1     = StdAtom.create(valid_atom_params)
        @aa_atom2     = StdAtom.create(valid_atom_params)
        @aa_atom3     = StdAtom.create(valid_atom_params)
        @aa_atom4     = StdAtom.create(valid_atom_params)
        
        @aa_residue1.atoms << @aa_atom1
        @aa_residue1.atoms << @aa_atom2
        @aa_residue1.save!
        
        @aa_residue2.atoms << @aa_atom3
        @aa_residue2.atoms << @aa_atom4
        @aa_residue2.save!
        
        @aa_chain.residues << @aa_residue1
        @aa_chain.residues << @aa_residue2
        @aa_chain.save!
      end

      should "have two amino acid residues" do
        assert_equal 2, @aa_chain.residues.size
      end
      
      should "include all the residues" do
        assert @aa_chain.residues.include?(@aa_residue1)
        assert @aa_chain.residues.include?(@aa_residue2)
      end
      
      should "have four atoms" do
        assert_equal 4, @aa_chain.atoms.size
      end
      
      should "include all the atoms" do
        assert @aa_chain.atoms.include?(@aa_atom1)
        assert @aa_chain.atoms.include?(@aa_atom2)
        assert @aa_chain.atoms.include?(@aa_atom3)
        assert @aa_chain.atoms.include?(@aa_atom4)
      end
      
      
      context "contacting each other" do
        
        setup do
          @contact1                 = Contact.new
          @contact1.atom            = @aa_atom1
          @contact1.contacting_atom = @aa_atom2
          @contact1.distance        = @aa_atom1 - @aa_atom2
          @contact1.save!
          
          @contact2                 = Contact.new
          @contact2.atom            = @aa_atom3
          @contact2.contacting_atom = @aa_atom4
          @contact2.distance        = @aa_atom3 - @aa_atom4
          @contact2.save!
        end
        
        should "have two contacts" do
          assert_equal 2, @aa_chain.contacts.size
        end
      end
    end
  end
end


class PseudoChainTest < ChainTest
                    
  should_have_many  :dna_residues

  should_have_many  :rna_residues
  
  should_have_many  :dna_atoms,
                    :through => :dna_residues
                    
  should_have_many  :rna_atoms,
                    :through => :rna_residues
end