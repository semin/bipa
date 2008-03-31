require File.dirname(__FILE__) + '/../test_helper'

class ScopDomainTest < Test::Unit::TestCase

  should_have_many  :dna_interfaces
  
  should_have_many  :rna_interfaces
  
  should_have_many  :residues
  
  should_have_many  :chains,   
                    :through => :residues
  
  should_have_many  :atoms,
                    :through => :residues
  
  should_have_many  :contacts,
                    :through => :atoms
  
  should_have_many  :contacting_atoms,
                    :through => :contacts
  
  should_have_many  :whbonds,
                    :through      => :atoms
  # 
  # has_many  :whbonding_atoms,
  #           :through      => :whbonds
  # 
  # has_many  :hbonds_as_donor,
  #           :through      => :atoms
  # 
  # has_many  :hbonds_as_acceptor,
  #           :through      => :atoms
  # 
  # has_many  :hbonding_donors,
  #           :through      => :hbonds_as_acceptor
  # 
  # has_many  :hbonding_acceptors,
  #           :through      => :hbonds_as_donor
end
