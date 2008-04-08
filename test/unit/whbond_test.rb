require File.dirname(__FILE__) + '/../test_helper'

class WhbondTest < Test::Unit::TestCase

  should_belong_to  :atom
              
  should_belong_to  :whbonding_atom
                
  should_belong_to  :water_atom
end
