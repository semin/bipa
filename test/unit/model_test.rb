require File.dirname(__FILE__) + '/../test_helper'

class ModelTest < Test::Unit::TestCase
  
  should_belong_to  :structure
  
  should_have_many  :chains
  
  should_have_many  :aa_chains

  should_have_many  :na_chains

  should_have_many  :dna_chains

  should_have_many  :rna_chains

  should_have_many  :hna_chains

  should_have_many  :het_chains

  # should_have_many  :residues,
  #                   :through => :chains
  # 
  # should_have_many  :atoms,
  #                   :through => :residues
  # 
  # should_have_many  :contacts,
  #                   :through => :atoms
  # 
  # should_have_many  :contacting_atoms,
  #                   :through => :contacts
  #                   
  # should_have_many  :hbonds_as_donor,
  #                   :through => :atoms
  #                   
  # should_have_many  :hbonds_as_acceptor,
  #                   :through => :atoms
  # 
  # should_have_many  :hbonding_donors,
  #                   :through => :hbonds_as_acceptor
  #                   
  # should_have_many  :hbonding_acceptors,
  #                   :through => :hbonds_as_donor
  # 
  # should_have_many  :whbonds,
  #                   :through => :atoms
  # 
  # should_have_many  :whbonding_atoms,
  #                   :through => :whbonds
end