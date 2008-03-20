require File.dirname(__FILE__) + '/../test_helper'

class StructureTest < Test::Unit::TestCase
  
  def setup
    @structure = Structure.new(:pdb_code => "abcd")
  end
  
  def test_structure_pdb_code
    assert_equal "abcd", @structure.pdb_code
  end
  
  def test_fails
    assert true
  end
end