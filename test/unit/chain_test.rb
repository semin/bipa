require File.dirname(__FILE__) + '/../test_helper'

class ChainTest < Test::Unit::TestCase
  
  should_belong_to  :model
  
  should_have_many  :residues
  
  should_have_many  :atoms,
                    :through => :residues

  should_have_many  :contacts,
                    :through => :residues

  # should_have_many  :contacting_atoms,
  #                   :through => :contacts
                    
  should_have_many  :hbonds_as_donor,
                    :through => :residues
                    
  should_have_many  :hbonds_as_acceptor,
                    :through => :residues
  
  # should_have_many  :hbonding_donors,
  #                   :through => :hbonds_as_acceptor
  #                   
  # should_have_many  :hbonding_acceptors,
  #                   :through => :hbonds_as_donor

  should_have_many  :whbonds,
                    :through => :residues
  
  # should_have_many  :whbonding_atoms,
  #                   :through => :whbonds
end


class AaChainTest < Test::Unit::TestCase

  should_have_many  :dna_interfaces

  should_have_many  :rna_interfaces
  
  should_have_many  :domains,
                    :through => :residues


  context "A AaChain instance" do
    
    context "with two amino acid residues having two atoms each" do
      
      setup do
        @aa_chain     = AaChain.new(valid_chain_params)
        @aa_residue1  = AaResidue.new(valid_residue_params(1, "ARG"))
        @aa_residue2  = AaResidue.new(valid_residue_params(1, "PHE"))
        @aa_atom1     = Atom.new(valid_atom_params)
        @aa_atom2     = Atom.new(valid_atom_params)
        @aa_atom3     = Atom.new(valid_atom_params)
        @aa_atom4     = Atom.new(valid_atom_params)
        
        @aa_residue1.atoms << @aa_atom1
        @aa_residue1.atoms << @aa_atom2
        
        @aa_residue2.atoms << @aa_atom3
        @aa_residue2.atoms << @aa_atom4
        
        @aa_chain.residues << @aa_residue1
        @aa_chain.residues << @aa_residue2
        
        @aa_chain.save
      end

      should "have two amino acid residues" do
        assert_equal 2, @aa_chain.residues.size
      end
      
      should "include all the residues" do
        assert_equal @aa_residue1, @aa_chain.residues[0]
        assert_equal @aa_residue2, @aa_chain.residues[1]
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
          @contact1 = Contact.new
          @contact1.atom = @aa_atom1
          @contact1.contacting_atom = @aa_atom2
          @contact1.distance = @aa_atom1 - @aa_atom2
          @contact1.save
          
          @contact2 = Contact.new
          @contact2.atom = @aa_atom3
          @contact2.contacting_atom = @aa_atom4
          @contact2.distance = @aa_atom3 - @aa_atom4
          @contact2.save
        end
        
        # should "have two contacts" do
        #   assert_equal 2, @aa_chain.contacts.size
        # end
      end
    end
  end
end

class HnaChainTest < Test::Unit::TestCase
                    
  should_have_many  :dna_residues

  should_have_many  :rna_residues
  
  should_have_many  :dna_atoms,
                    :through => :dna_residues
                    
  should_have_many  :rna_atoms,
                    :through => :rna_residues
end