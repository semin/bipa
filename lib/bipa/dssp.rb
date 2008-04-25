module Bipa
  class Dssp

    attr_reader :residues

    DsspLine = Struct.new(:dssp_number,
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
                          :sasa,
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
          dssp = DsspLine.new(line[0..4].strip,     #dssp_number
                              line[16..16].strip,   #sse
                              line[18..18].strip,   #three_turns
                              line[19..19].strip,   #four_turns
                              line[20..20].strip,   #five_turns
                              line[21..21].strip,   #geometrical_bend
                              line[22..22].strip,   #chirality
                              line[23..23].strip,   #beta_bridge_label_1
                              line[24..24].strip,   #beta_bridge_label_2
                              line[26..28].strip,   #beta_brdige_partner_residue_number_1
                              line[30..32].strip,   #beta_brdige_partner_residue_number_2
                              line[33..33].strip,   #beta_sheet_label
                              line[34..37].strip,   #sasa
                              line[39..44].strip,   #nh_o_hbond_1_acceptor
                              line[46..49].strip,   #nh_o_hbond_1_energy
                              line[51..55].strip,   #o_hn_hbond_1_donor
                              line[57..60].strip,   #o_hn_hbond_1_energy
                              line[62..66].strip,   #nh_o_hbond_2_acceptor
                              line[68..71].strip,   #nh_o_hbond_2_energy
                              line[73..77].strip,   #o_hn_hbond_2_donor
                              line[79..82].strip,   #o_hn_hbond_2_energy
                              line[84..90].strip,   #tco
                              line[91..96].strip,   #kappa
                              line[97..102].strip,  #alpha
                              line[103..108].strip, #phi
                              line[109..114].strip) #psi

          @residues[line[5..11].gsub(/\s+/, '')] = dssp
        end
      end
    end
  end

end
