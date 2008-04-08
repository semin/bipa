require File.dirname(__FILE__) + '/../test_helper'

class ContactTest < Test::Unit::TestCase
  
  should_belong_to  :atom

  should_belong_to  :contacting_atom
end