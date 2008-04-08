require File.dirname(__FILE__) + '/../test_helper'

class SubfamilyTest < Test::Unit::TestCase
  
  should_belong_to  :family

  context "A Subfamily instance" do
    
    should "return correct representative when sending #representative" do
      
      sub_fam = Subfamily.new
      domain1 = stub(:calpha_only? => false,  :resolution => 2.5)
      domain2 = stub(:calpha_only? => true,   :resolution => 1.0)
      domain3 = stub(:calpha_only? => false,  :resolution => 3.0)
      sub_fam.stubs(:domains).returns([domain1, domain2, domain3])
      
      assert_equal domain1, sub_fam.representative
    end
  end
end

(10..100).step(10) do |si|
  eval <<-END
    class Subfamily#{si}Test < SubfamilyTest

      should_have_one :alignment

      should_have_many  :domains
    end
  END
end
