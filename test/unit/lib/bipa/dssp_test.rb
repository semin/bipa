require File.dirname(__FILE__) + '/../../../test_helper'

class DsspTest < Test::Unit::TestCase
  
  def setup
    dssp_file = "./1a02.dssp"
    @dssp = Bipa::Dssp.new(IO.read(dssp_file))
  end

  def test_return_size
    assert_equal(4, @dssp.sstruc.size)
  end

  def test_fist_residue
    assert_equal('', @dssp.sstruc['A1'])
  end

  def test_third_residue
    assert_equal('E', @dssp.sstruc['A3'])
  end

  def test_last_residue
    assert_equal('E', @dssp.sstruc['A4'])
  end
end