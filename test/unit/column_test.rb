require File.dirname(__FILE__) + '/../test_helper'

class ColumnTest < Test::Unit::TestCase
  
  should_belong_to :alignment

  should_have_many :positions
end