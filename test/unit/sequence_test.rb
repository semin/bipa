require File.dirname(__FILE__) + '/../test_helper'

class SequenceTest < Test::Unit::TestCase
  
  should_belong_to  :alignment

  should_belong_to  :domain

  should_belong_to  :chain

  should_have_many :columns
end