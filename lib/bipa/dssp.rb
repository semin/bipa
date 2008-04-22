module Bipa
  
  class Dssp
    attr_reader :residues

    def initialize(dssp_str)
      @residues = {}

      dssp_str.each_line do |line|
        next if line =~ /^\s*#/
        if line.length == 137
          resnum      = line[5..9].strip
          icode       = line[10..10].strip
          chainid     = line[11..11].strip
          resname     = line[13..14].strip
          sse         = line[16..16].strip
          three_turns = line[18..18].strip
          four_turns  = line[19..19].strip
          five_turns  = line[20..20].strip
          geo_bend    = line[21..21].strip
          chirality   = line[22..22].strip
          beta_bridge_label1 = line[23..23].strip
          beta_bridge_label2 = line[24..24].strip
          

          @residues["#{res_chain}#{res_number}#{res_icode}"] = res_sstruc
        end
      end
    end
  end
  
end