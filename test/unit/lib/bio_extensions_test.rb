require File.dirname(__FILE__) + '/../../test_helper'

class BioExtensionsTest < Test::Unit::TestCase
  
  def setup
    @pdb_bio = Bio::PDB.new(IO.read("./10mh.pdb"))
  end
  
  def test_Bio_PDB_deposition_date
    assert_equal "1999-10-10", @pdb_bio.deposition_date
  end
  
  def test_Bio_PDB_resolution
    assert_equal 2.5, @pdb_bio.resolution
  end
end