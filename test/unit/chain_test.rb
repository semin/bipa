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
end

class HnaChainTest < Test::Unit::TestCase

  should_have_many  :dna_residues

  should_have_many  :rna_residues
  
  should_have_many  :dna_atoms,
                    :through => :dna_residues
                    
  should_have_many  :rna_atoms,
                    :through => :rna_residues
end