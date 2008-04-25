require File.dirname(__FILE__) + '/../../../test_helper'

class DsspTest < Test::Unit::TestCase

  context "A Dssp instance" do
    
    setup do
      dssp_str = <<END
  #  RESIDUE AA STRUCTURE BP1 BP2  ACC     N-H-->O    O-->H-N    N-H-->O    O-->H-N    TCO  KAPPA ALPHA  PHI   PSI    X-CA   Y-CA   Z-CA 
    4    4 A I        +     0   0   28     -2,-0.4     3,-0.1    26,-0.3   308,-0.0  -0.876  18.3 178.8-103.4 125.7  -26.8   30.1   63.6
    5    5 A K  S    S+     0   0  213     -2,-0.5     2,-1.3     1,-0.2    -1,-0.2   0.859  74.0  61.4 -88.1 -42.3  -27.2   28.7   60.1
    6    6 A D  S    S-     0   0   93      1,-0.1     2,-2.6     2,-0.0    -1,-0.2  -0.693  74.1-159.1 -86.8  88.6  -23.6   28.9   58.9
  281        !*             0   0    0      0, 0.0     0, 0.0     0, 0.0     0, 0.0   0.000 360.0 360.0 360.0 360.0    0.0    0.0    0.0
  282  140 F R     >        0   0  193      0, 0.0     4,-1.5     0, 0.0     5,-0.2   0.000 360.0 360.0 360.0 136.6   58.5   28.1   30.6
  283  141 F R  H  >  +     0   0  188      1,-0.2     4,-1.4     2,-0.2     5,-0.1   0.796 360.0  46.8 -50.6 -32.4   55.8   25.6   31.5
  284  142 F I  H  > S+     0   0   72      2,-0.2     4,-1.9     1,-0.2     3,-0.3   0.947 104.3  55.2 -79.4 -47.7   57.9   24.6   34.6
END
      
      @dssp = Bipa::Dssp.new(dssp_str)
      @residues = @dssp.residues
    end
      
    should "return correct number of residues" do
      assert_equal(6, @residues.size)
      assert(@residues.is_a?(Hash))
    end

    should "return correct secondary structure element when sending #sse" do
      assert_equal("",  @residues["4A"].sse)
      assert_equal("S", @residues["5A"].sse)
      assert_equal("S", @residues["6A"].sse)
      assert_equal("",  @residues["140F"].sse)
      assert_equal("H", @residues["141F"].sse)
      assert_equal("H", @residues["142F"].sse)
    end
    
    should "return correct #three_turns" do
    end
    
    should "return correct #four_turns" do
    end
    
    should "return correct #five_turns" do
    end
    
    should "return correct #geometrical_bend" do
    end
    
    should "return correct #chirality" do
    end
    
    should "return correct #beta_bridge_label_1" do
    end
    
    should "return correct #beta_bridge_label_2" do
    end
    
    should "return correct #beta_brdige_partner_residue_number_1" do
    end
    
    should "return correct #beta_brdige_partner_residue_number_2" do
    end
    
    should "return correct #beta_sheet_label" do
    end
    
    should "return correct #sasa" do
    end
    
    should "return correct #nh_o_hbond_1_acceptor" do
    end
    
    should "return correct #nh_o_hbond_1_energy" do
    end
    
    should "return correct #o_hn_hbond_1_donor" do
    end
    
    should "return correct #o_hn_hbond_1_energy" do
    end
    
    should "return correct #nh_o_hbond_2_acceptor" do
    end
    
    should "return correct #nh_o_hbond_2_energy" do
    end
    
    should "return correct #o_hn_hbond_2_donor" do
    end
    
    should "return correct #o_hn_hbond_2_energy" do
    end
    
    should "return correct #tco" do
    end
    
    should "return correct #kappa" do
    end
    
    should "return correct #alpha" do
    end
    
    should "return correct #phi" do
    end
    
    should "return correct #psi" do
    end
  
  end
end