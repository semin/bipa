require File.dirname(__FILE__) + '/../../test_helper'

class BioExtensionsTest < Test::Unit::TestCase
  
  def setup
    @pdb_bio = Bio::PDB.new(IO.read(File.dirname(__FILE__) + "/10mh.pdb"))
  end
  
  def test_Bio_PDB_deposition_date
    assert_equal "10-AUG-1998", @pdb_bio.deposition_date
  end
  
  def test_Bio_PDB_resolution
    assert_equal 2.55, @pdb_bio.resolution
  end
  
  def test_Bio_PDB_exp_method
    assert_equal "X-RAY DIFFRACTION", @pdb_bio.exp_method
  end
  
  def test_Bio_PDB_Model_aa_chains
    assert_equal 1, @pdb_bio.models.first.aa_chains.size
    assert_equal "A", @pdb_bio.models.first.aa_chains.first.id
  end
  
  def test_Bio_PDB_Model_aa_chains
    assert_equal 2, @pdb_bio.models.first.na_chains.size
    assert_equal "B", @pdb_bio.models.first.na_chains[0].id
    assert_equal "C", @pdb_bio.models.first.na_chains[1].id
  end
end