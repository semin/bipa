module Bipa
  class Dssp
    
    attr :residues

    Dssp = Struct.new(:dssp_number,
                      :residue_number,
                      :icode,
                      :chain_id,
                      :residue_name,
                      :sse,
                      :three_turns,
                      :four_turns,
                      :five_turns,
                      :geometrical_bend,
                      :chirality,
                      :beta_bridge_label_1,
                      :beta_bridge_label_2,
                      :beta_brdige_partner_residue_number_1,
                      :beta_brdige_partner_residue_number_2,
                      :beta_sheet_label,
                      :solvent_accessibility,
                      :nh_o_hbond_1_acceptor,
                      :nh_o_hbond_1_energy,
                      :o_hn_hbond_1_donor,
                      :o_hn_hbond_1_energy,
                      :nh_o_hbond_2_acceptor,
                      :nh_o_hbond_2_energy,
                      :o_hn_hbond_2_donor,
                      :o_hn_hbond_2_energy,
                      :tco,
                      :kappa,
                      :alpha,
                      :phi,
                      :psi)

    def initialize(dssp_str)
      @residues = Hash.new

      dssp_str.each_line do |line|
        next if line =~ /^\s*#/
        if line.length == 137 && !line[5..9].strip.blank?
          dssp = Dssp.new(line[0..4].strip,
                          line[5..9].strip,
                          line[10..10].strip, 
                          line[11..11].strip, 
                          line[13..14].strip, 
                          line[16..16].strip, 
                          line[18..18].strip, 
                          line[19..19].strip, 
                          line[20..20].strip, 
                          line[21..21].strip, 
                          line[22..22].strip, 
                          line[23..23].strip, 
                          line[24..24].strip, 
                          line[26..28].strip, 
                          line[30..32].strip, 
                          line[33..33].strip, 
                          line[34..37].strip, 
                          line[39..44].strip, 
                          line[46..49].strip, 
                          line[51..55].strip, 
                          line[57..60].strip, 
                          line[62..66].strip, 
                          line[68..71].strip, 
                          line[73..77].strip, 
                          line[79..82].strip, 
                          line[84..90].strip, 
                          line[91..96].strip, 
                          line[97..102].strip,
                          line[103..108].strip,
                          line[109..114].strip)

          @residues[line[5..11].gsub(/\s+/, '')] = dssp
        end
      end
    end
  end
  
end