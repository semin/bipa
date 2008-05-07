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
      assert_equal("C", @residues["4A"].sse)
      assert_equal("S", @residues["5A"].sse)
      assert_equal("S", @residues["6A"].sse)
      assert_equal("C", @residues["140F"].sse)
      assert_equal("H", @residues["141F"].sse)
      assert_equal("H", @residues["142F"].sse)
    end
    
    should "return correct #three_turns" do
      assert_equal(nil, @residues["4A"].three_turns)
      assert_equal(nil, @residues["5A"].three_turns)
      assert_equal(nil, @residues["6A"].three_turns)
      assert_equal(nil, @residues["140F"].three_turns)
      assert_equal(nil, @residues["141F"].three_turns)
      assert_equal(nil, @residues["142F"].three_turns)
    end
    
    should "return correct #four_turns" do
      assert_equal(nil,  @residues["4A"].four_turns)
      assert_equal(nil,  @residues["5A"].four_turns)
      assert_equal(nil,  @residues["6A"].four_turns)
      assert_equal(">", @residues["140F"].four_turns)
      assert_equal(">", @residues["141F"].four_turns)
      assert_equal(">", @residues["142F"].four_turns)
    end
    
    should "return correct #five_turns" do
      assert_equal(nil, @residues["4A"].five_turns)
      assert_equal(nil, @residues["5A"].five_turns)
      assert_equal(nil, @residues["6A"].five_turns)
      assert_equal(nil, @residues["140F"].five_turns)
      assert_equal(nil, @residues["141F"].five_turns)
      assert_equal(nil, @residues["142F"].five_turns)
    end
    
    should "return correct #geometrical_bend" do
      assert_equal(nil,  @residues["4A"].geometrical_bend)
      assert_equal("S", @residues["5A"].geometrical_bend)
      assert_equal("S", @residues["6A"].geometrical_bend)
      assert_equal(nil,  @residues["140F"].geometrical_bend)
      assert_equal(nil,  @residues["141F"].geometrical_bend)
      assert_equal("S", @residues["142F"].geometrical_bend)
    end
    
    should "return correct #chirality" do
      assert_equal("+", @residues["4A"].chirality)
      assert_equal("+", @residues["5A"].chirality)
      assert_equal("-", @residues["6A"].chirality)
      assert_equal(nil,  @residues["140F"].chirality)
      assert_equal("+", @residues["141F"].chirality)
      assert_equal("+", @residues["142F"].chirality)
    end
    
    should "return correct #beta_bridge_label_1" do
      assert_equal(nil, @residues["4A"].beta_bridge_label_1)
      assert_equal(nil, @residues["5A"].beta_bridge_label_1)
      assert_equal(nil, @residues["6A"].beta_bridge_label_1)
      assert_equal(nil, @residues["140F"].beta_bridge_label_1)
      assert_equal(nil, @residues["141F"].beta_bridge_label_1)
      assert_equal(nil, @residues["142F"].beta_bridge_label_1)
    end
    
    should "return correct #beta_bridge_label_2" do
      assert_equal(nil, @residues["4A"].beta_bridge_label_2)
      assert_equal(nil, @residues["5A"].beta_bridge_label_2)
      assert_equal(nil, @residues["6A"].beta_bridge_label_2)
      assert_equal(nil, @residues["140F"].beta_bridge_label_2)
      assert_equal(nil, @residues["141F"].beta_bridge_label_2)
      assert_equal(nil, @residues["142F"].beta_bridge_label_2)
    end
    
    should "return correct #beta_brdige_partner_residue_number_1" do
      assert_equal(0, @residues["4A"].beta_brdige_partner_residue_number_1)
      assert_equal(0, @residues["5A"].beta_brdige_partner_residue_number_1)
      assert_equal(0, @residues["6A"].beta_brdige_partner_residue_number_1)
      assert_equal(0, @residues["140F"].beta_brdige_partner_residue_number_1)
      assert_equal(0, @residues["141F"].beta_brdige_partner_residue_number_1)
      assert_equal(0, @residues["142F"].beta_brdige_partner_residue_number_1)
    end
    
    should "return correct #beta_brdige_partner_residue_number_2" do
      assert_equal(0, @residues["4A"].beta_brdige_partner_residue_number_2)
      assert_equal(0, @residues["5A"].beta_brdige_partner_residue_number_2)
      assert_equal(0, @residues["6A"].beta_brdige_partner_residue_number_2)
      assert_equal(0, @residues["140F"].beta_brdige_partner_residue_number_2)
      assert_equal(0, @residues["141F"].beta_brdige_partner_residue_number_2)
      assert_equal(0, @residues["142F"].beta_brdige_partner_residue_number_2)
    end
    
    should "return correct #beta_sheet_label" do
      assert_equal(nil, @residues["4A"].beta_sheet_label)
      assert_equal(nil, @residues["5A"].beta_sheet_label)
      assert_equal(nil, @residues["6A"].beta_sheet_label)
      assert_equal(nil, @residues["140F"].beta_sheet_label)
      assert_equal(nil, @residues["141F"].beta_sheet_label)
      assert_equal(nil, @residues["142F"].beta_sheet_label)
    end
    
    should "return correct #sasa" do
      assert_equal(28,  @residues["4A"].sasa)
      assert_equal(213, @residues["5A"].sasa)
      assert_equal(93,  @residues["6A"].sasa)
      assert_equal(193, @residues["140F"].sasa)
      assert_equal(188, @residues["141F"].sasa)
      assert_equal(72,  @residues["142F"].sasa)
    end

    should "return correct #nh_o_hbond_1_acceptor" do
      assert_equal(-2,  @residues["4A"].nh_o_hbond_1_acceptor)
      assert_equal(-2,  @residues["5A"].nh_o_hbond_1_acceptor)
      assert_equal(1,   @residues["6A"].nh_o_hbond_1_acceptor)
      assert_equal(0,   @residues["140F"].nh_o_hbond_1_acceptor)
      assert_equal(1,   @residues["141F"].nh_o_hbond_1_acceptor)
      assert_equal(2,   @residues["142F"].nh_o_hbond_1_acceptor)
    end
    
    should "return correct #nh_o_hbond_1_energy" do
      assert_equal(-0.4,  @residues["4A"].nh_o_hbond_1_energy)
      assert_equal(-0.5,  @residues["5A"].nh_o_hbond_1_energy)
      assert_equal(-0.1,  @residues["6A"].nh_o_hbond_1_energy)
      assert_equal( 0.0,  @residues["140F"].nh_o_hbond_1_energy)
      assert_equal(-0.2,  @residues["141F"].nh_o_hbond_1_energy)
      assert_equal(-0.2,  @residues["142F"].nh_o_hbond_1_energy)
    end
    
    should "return correct #o_hn_hbond_1_donor" do
      assert_equal(3, @residues["4A"].o_hn_hbond_1_donor)
      assert_equal(2, @residues["5A"].o_hn_hbond_1_donor)
      assert_equal(2, @residues["6A"].o_hn_hbond_1_donor)
      assert_equal(4, @residues["140F"].o_hn_hbond_1_donor)
      assert_equal(4, @residues["141F"].o_hn_hbond_1_donor)
      assert_equal(4, @residues["142F"].o_hn_hbond_1_donor)
    end            
    
    should "return correct #o_hn_hbond_1_energy" do
      assert_equal(-0.1,  @residues["4A"].o_hn_hbond_1_energy)
      assert_equal(-1.3,  @residues["5A"].o_hn_hbond_1_energy)
      assert_equal(-2.6,  @residues["6A"].o_hn_hbond_1_energy)
      assert_equal(-1.5,  @residues["140F"].o_hn_hbond_1_energy)
      assert_equal(-1.4,  @residues["141F"].o_hn_hbond_1_energy)
      assert_equal(-1.9,  @residues["142F"].o_hn_hbond_1_energy)
    end
    
    should "return correct #nh_o_hbond_2_acceptor" do
      assert_equal(26, @residues["4A"].nh_o_hbond_2_acceptor)
      assert_equal( 1, @residues["5A"].nh_o_hbond_2_acceptor)
      assert_equal( 2, @residues["6A"].nh_o_hbond_2_acceptor)
      assert_equal( 0, @residues["140F"].nh_o_hbond_2_acceptor)
      assert_equal( 2, @residues["141F"].nh_o_hbond_2_acceptor)
      assert_equal( 1, @residues["142F"].nh_o_hbond_2_acceptor)
    end             
    
    should "return correct #nh_o_hbond_2_energy" do
      assert_equal(-0.3,  @residues["4A"].nh_o_hbond_2_energy)
      assert_equal(-0.2,  @residues["5A"].nh_o_hbond_2_energy)
      assert_equal(-0.0,  @residues["6A"].nh_o_hbond_2_energy)
      assert_equal( 0.0,  @residues["140F"].nh_o_hbond_2_energy)
      assert_equal(-0.2,  @residues["141F"].nh_o_hbond_2_energy)
      assert_equal(-0.2,  @residues["142F"].nh_o_hbond_2_energy)
    end
    
    should "return correct #o_hn_hbond_2_donor" do
      assert_equal(308, @residues["4A"].o_hn_hbond_2_donor)
      assert_equal(-1,  @residues["5A"].o_hn_hbond_2_donor)
      assert_equal(-1,  @residues["6A"].o_hn_hbond_2_donor)
      assert_equal(5,   @residues["140F"].o_hn_hbond_2_donor)
      assert_equal(5,   @residues["141F"].o_hn_hbond_2_donor)
      assert_equal(3,   @residues["142F"].o_hn_hbond_2_donor)
    end
    
    should "return correct #o_hn_hbond_2_energy" do
      assert_equal(-0.0,  @residues["4A"].o_hn_hbond_2_energy)
      assert_equal(-0.2,  @residues["5A"].o_hn_hbond_2_energy)
      assert_equal(-0.2,  @residues["6A"].o_hn_hbond_2_energy)
      assert_equal(-0.2,  @residues["140F"].o_hn_hbond_2_energy)
      assert_equal(-0.1,  @residues["141F"].o_hn_hbond_2_energy)
      assert_equal(-0.3,  @residues["142F"].o_hn_hbond_2_energy)
    end
    
    should "return correct #tco" do
      assert_equal(-0.876,  @residues["4A"].tco)
      assert_equal( 0.859,  @residues["5A"].tco)
      assert_equal(-0.693,  @residues["6A"].tco)
      assert_equal( 0.000,  @residues["140F"].tco)
      assert_equal( 0.796,  @residues["141F"].tco)
      assert_equal( 0.947,  @residues["142F"].tco)
    end
    
    should "return correct #kappa" do
      assert_equal( 18.3,  @residues["4A"].kappa)
      assert_equal( 74.0,  @residues["5A"].kappa)
      assert_equal( 74.1,  @residues["6A"].kappa)
      assert_equal(360.0,  @residues["140F"].kappa)
      assert_equal(360.0,  @residues["141F"].kappa)
      assert_equal(104.3,  @residues["142F"].kappa)
    end
    
    should "return correct #alpha" do
      assert_equal(178.8,   @residues["4A"].alpha)
      assert_equal(61.4,    @residues["5A"].alpha)
      assert_equal(-159.1,  @residues["6A"].alpha)
      assert_equal(360.0,   @residues["140F"].alpha)
      assert_equal(46.8,    @residues["141F"].alpha)
      assert_equal(55.2,    @residues["142F"].alpha)
    end             
    
    should "return correct #phi" do
      assert_equal(-103.4,  @residues["4A"].phi)
      assert_equal(-88.1,   @residues["5A"].phi)
      assert_equal(-86.8,   @residues["6A"].phi)
      assert_equal( 360.0,  @residues["140F"].phi)
      assert_equal(-50.6,   @residues["141F"].phi)
      assert_equal(-79.4,   @residues["142F"].phi)
    end
    
    should "return correct #psi" do
      assert_equal(125.7, @residues["4A"].psi)
      assert_equal(-42.3, @residues["5A"].psi)
      assert_equal(88.6,  @residues["6A"].psi)
      assert_equal(136.6, @residues["140F"].psi)
      assert_equal(-32.4, @residues["141F"].psi)
      assert_equal(-47.7, @residues["142F"].psi)
    end
  end
end