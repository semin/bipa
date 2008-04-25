require File.dirname(__FILE__) + '/../test_helper'

class ModelTest < Test::Unit::TestCase
  
  should_belong_to  :structure
  
  should_have_many  :chains
  
  should_have_many  :aa_chains

  should_have_many  :na_chains

  should_have_many  :dna_chains

  should_have_many  :rna_chains

  should_have_many  :hna_chains

  should_have_many  :pseudo_chains
end