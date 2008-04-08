require File.dirname(__FILE__) + '/../test_helper'

class HbondTest < Test::Unit::TestCase
  
  should_belong_to  :donor

  should_belong_to  :acceptor
end