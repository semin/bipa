require File.dirname(__FILE__) + '/../test_helper'

class StructureTest < Test::Unit::TestCase
  
  def test_structure_pdb_code
    structure = Structure.new(:pdb_code => "abcd")
    assert_equal "abcd", structure.pdb_code
  end

end