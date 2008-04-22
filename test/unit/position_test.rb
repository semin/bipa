require File.dirname(__FILE__) + '/../test_helper'

class PositionTest < Test::Unit::TestCase
  
  should_belong_to :sequence
  
  should_belong_to :column
  
  should_belong_to :residue
end