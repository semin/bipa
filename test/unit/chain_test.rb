require File.dirname(__FILE__) + '/../test_helper'

class ChainTest < Test::Unit::TestCase
  
  should_belong_to  :model
  
  should_have_many  :residues
  
  should_have_many  :atoms,
                    :through => :residues

  should_have_many  :contacts,
                    :through => :atoms

  # should_have_many  :contacting_atoms,
  #                   :through => :contacts
                    
  should_have_many  :hbonds_as_donor,
                    :through => :atoms
                    
  should_have_many  :hbonds_as_acceptor,
                    :through => :atoms
  
  # should_have_many  :hbonding_donors,
  #                   :through => :hbonds_as_acceptor
  #                   
  # should_have_many  :hbonding_acceptors,
  #                   :through => :hbonds_as_donor

  should_have_many  :whbonds,
                    :through => :atoms
  
  # should_have_many  :whbonding_atoms,
  #                   :through => :whbonds
end


class AaChainTest < Test::Unit::TestCase

  should_have_many  :dna_interfaces

  should_have_many  :rna_interfaces
  
  should_have_many  :domains,
                    :through => :residues


  context "A AaChain instance" do
    
    context "with two amino acid residues having two atoms for each" do
      
      setup do
        @aa_chain     = AaChain.new(valid_chain_params)
        @aa_residue1  = AaResidue.new(valid_residue_params(1, "ARG"))
        @aa_residue2  = AaResidue.new(valid_residue_params(1, "PHE"))
        @aa_atom1     = Atom.new(valid_atom_params)
        @aa_atom2     = Atom.new(valid_atom_params)
        @aa_atom3     = Atom.new(valid_atom_params)
        @aa_atom4     = Atom.new(valid_atom_params)
        @contact1     = Contact.new(:atom_id            => @aa_atom1,
                                    :contacting_atom_id => @aa_atom2)
        @contact2     = Contact.new(:atom_id            => @aa_atom3,
                                    :contacting_atom_id => @aa_atom4)
        
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
      
      should "have residues in the order of input" do
        assert_equal @aa_residue1, @aa_chain.residues[0]
        assert_equal @aa_residue2, @aa_chain.residues[1]
      end
      
      should "directly access every atom of the residue" do
        assert_equal 4, @aa_chain.atoms.size
        assert @aa_chain.atoms.include?(@aa_atom1)
        assert @aa_chain.atoms.include?(@aa_atom2)
        assert @aa_chain.atoms.include?(@aa_atom3)
        assert @aa_chain.atoms.include?(@aa_atom4)
      end
      # 
      # should "directly access contacts between atoms" do
      #   assert_equal 2, @aa_chain.contacts.length
      # end
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