require File.dirname(__FILE__) + '/../test_helper'

class AlignmentTest < Test::Unit::TestCase

  should_have_many  :sequences
  
  should_have_many  :columns,
                    :through => :sequences
end


class FullAlignmentTest < AlignmentTest

  should_belong_to  :family
end


class SubfamilyAlignmentTest < AlignmentTest

  should_belong_to  :subfamily
end


(10..100).step(10) do |si|
  eval <<-EVAL
    class Rep#{si}AlignmentTest < AlignmentTest

      should_belong_to  :family
    end
  EVAL
end
