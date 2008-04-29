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
          dssp = DsspLine.new(line[0..4].strip.to_i,      #dssp_number
                              line[16..16].strip.blank? ? "C" : line[16..16].strip,         #sse
                              line[18..18].strip.nil_if_blank,  #three_turns
                              line[19..19].strip.nil_if_blank,  #four_turns
                              line[20..20].strip.nil_if_blank,  #five_turns
                              line[21..21].strip.nil_if_blank,  #geometrical_bend
                              line[22..22].strip.nil_if_blank,  #chirality
                              line[23..23].strip.nil_if_blank,  #beta_bridge_label_1
                              line[24..24].strip.nil_if_blank,  #beta_bridge_label_2
                              line[26..28].strip.to_i,          #beta_brdige_partner_residue_number_1
                              line[30..32].strip.to_i,          #beta_brdige_partner_residue_number_2
                              line[33..33].strip.nil_if_blank,  #beta_sheet_label
                              line[34..37].strip.to_f,          #sasa
                              line[39..44].strip.to_i,          #nh_o_hbond_1_acceptor
                              line[46..49].strip.to_f,          #nh_o_hbond_1_energy
                              line[51..55].strip.to_i,          #o_hn_hbond_1_donor
                              line[57..60].strip.to_f,          #o_hn_hbond_1_energy
                              line[62..66].strip.to_i,          #nh_o_hbond_2_acceptor
                              line[68..71].strip.to_f,          #nh_o_hbond_2_energy
                              line[73..77].strip.to_i,          #o_hn_hbond_2_donor
                              line[79..82].strip.to_f,          #o_hn_hbond_2_energy
                              line[84..90].strip.to_f,          #tco
                              line[91..96].strip.to_f,          #kappa
                              line[97..102].strip.to_f,         #alpha
                              line[103..108].strip.to_f,        #phi
                              line[109..114].strip.to_f)        #psi

          @residues[line[5..11].gsub(/\s+/, '')] = dssp
        end
      end
    end

  end
end
