require File.dirname(__FILE__) + '/../test_helper'

class ChainTest < Test::Unit::TestCase
  
  should_belong_to  :model
  
  should_have_many  :residues
  
  should_have_many  :atoms,
                    :through => :residues

  should_have_many  :contacts,
                    :through => :atoms

  should_have_many  :contacting_atoms,
                    :through => :contacts
                    
  should_have_many  :hbonds_as_donor,
                    :through => :atoms
                    
  should_have_many  :hbonds_as_acceptor,
                    :through => :atoms
  
  should_have_many  :hbonding_donors,
                    :through => :hbonds_as_acceptor
                    
  should_have_many  :hbonding_acceptors,
                    :through => :hbonds_as_donor

  should_have_many  :whbonds,
                    :through => :atoms
  
  should_have_many  :whbonding_atoms,
                    :through => :whbonds
end


class AaChainTest < Test::Unit::TestCase
  
  should_have_many  :dna_interfaces

  should_have_many  :rna_interfaces
  
  should_have_many  :domains,
                    :through => :residues
                    
  context "A AaChain instance" do
    
    should "have correct residues" do
      aa_chain = AaChain.new(valid_chain_params)
      aa_residue1 = AaResidue.new(valid_residue_params(1, "ARG"))
      aa_residue2 = AaResidue.new(valid_residue_params(1, "PHE"))
      
      assert aa_chain.save
      assert_true 2, aa_chain.residues.size
      assert_true aa_residue1, aa_chain.residues[0]
      assert_true aa_residue2, aa_chain.residues[1]
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