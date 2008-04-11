require File.dirname(__FILE__) + '/../test_helper'

class GloriaTest < Test::Unit::TestCase
  def test_default
    assert true
  end
end


class ResMapTest < GloriaTest

  should_have_one :residue
end


class ResidueMapTest < GloriaTest

  should_have_one :residue
end