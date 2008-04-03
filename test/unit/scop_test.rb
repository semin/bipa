require File.dirname(__FILE__) + '/../test_helper'

class ScopDomainTest < Test::Unit::TestCase

  should_have_many  :dna_interfaces
  
  should_have_many  :rna_interfaces
  
  should_have_many  :residues
  
  should_have_many  :chains,   
                    :through => :residues
  
  # should_have_many  :atoms,
  #                   :through => :residues
  # 
  # should_have_many  :contacts,
  #                   :through => :atoms
  # 
  # should_have_many  :contacting_atoms,
  #                   :through => :contacts
  # 
  # should_have_many  :whbonds,
  #                   :through      => :atoms
end
