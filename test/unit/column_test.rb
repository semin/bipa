require File.dirname(__FILE__) + '/../test_helper'

class ColumnTest < Test::Unit::TestCase
  
  should_belong_to :sequence

  should_belong_to :residue
end