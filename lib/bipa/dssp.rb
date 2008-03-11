module BIPA
  class DSSP
    attr_reader :sstruc

    def initialize(file_str)
      @sstruc = {}

      file_str.each do |line|
        next if line =~ /^\s*#/
        if line.length == 137
          res_number  = line[5..9].strip
          res_icode   = line[10..10].strip
          res_chain   = line[11..11].strip
          res_name    = line[13..14].strip
          res_sstruc  = line[16..16].strip
          @sstruc["#{res_chain}#{res_number}#{res_icode}"] = res_sstruc
        end
      end
    end
  end
end

if $0 == __FILE__

  require 'test/unit'

  class TestDSSP < Test::Unit::TestCase
    def setup
      test_str = <<END
==== Secondary Structure Definition by the program DSSP, updated CMBI version by ElmK / April 1,2000 ==== DATE=16-MAY-2007     .
REFERENCE W. KABSCH AND C.SANDER, BIOPOLYMERS 22 (1983) 2577-2637                                                              .
HEADER    DNA BINDING PROTEIN/DNA                 04-MAY-00   1C8C                                                             .
COMPND   2 MOLECULE: DNA-BINDING PROTEIN 7A;                                                                                   .
SOURCE   2 ORGANISM_SCIENTIFIC: SULFOLOBUS SOLFATARICUS;                                                                       .
AUTHOR    S.SU,Y.-G.GAO,H.ROBINSON,Y.-C.LIAW,S.P.EDMONDSON,                                                                    .
   64  1  0  0  0 TOTAL NUMBER OF RESIDUES, NUMBER OF CHAINS, NUMBER OF SS-BRIDGES(TOTAL,INTRACHAIN,INTERCHAIN)                .
  5010.0   ACCESSIBLE SURFACE OF PROTEIN (ANGSTROM**2)                                                                         .
   38 59.4   TOTAL NUMBER OF HYDROGEN BONDS OF TYPE O(I)-->H-N(J)  , SAME NUMBER PER 100 RESIDUES                              .
    0  0.0   TOTAL NUMBER OF HYDROGEN BONDS IN     PARALLEL BRIDGES, SAME NUMBER PER 100 RESIDUES                              .
   22 34.4   TOTAL NUMBER OF HYDROGEN BONDS IN ANTIPARALLEL BRIDGES, SAME NUMBER PER 100 RESIDUES                              .
    0  0.0   TOTAL NUMBER OF HYDROGEN BONDS OF TYPE O(I)-->H-N(I-5), SAME NUMBER PER 100 RESIDUES                              .
    1  1.6   TOTAL NUMBER OF HYDROGEN BONDS OF TYPE O(I)-->H-N(I-4), SAME NUMBER PER 100 RESIDUES                              .
    2  3.1   TOTAL NUMBER OF HYDROGEN BONDS OF TYPE O(I)-->H-N(I-3), SAME NUMBER PER 100 RESIDUES                              .
    0  0.0   TOTAL NUMBER OF HYDROGEN BONDS OF TYPE O(I)-->H-N(I-2), SAME NUMBER PER 100 RESIDUES                              .
    0  0.0   TOTAL NUMBER OF HYDROGEN BONDS OF TYPE O(I)-->H-N(I-1), SAME NUMBER PER 100 RESIDUES                              .
    0  0.0   TOTAL NUMBER OF HYDROGEN BONDS OF TYPE O(I)-->H-N(I+0), SAME NUMBER PER 100 RESIDUES                              .
    0  0.0   TOTAL NUMBER OF HYDROGEN BONDS OF TYPE O(I)-->H-N(I+1), SAME NUMBER PER 100 RESIDUES                              .
    2  3.1   TOTAL NUMBER OF HYDROGEN BONDS OF TYPE O(I)-->H-N(I+2), SAME NUMBER PER 100 RESIDUES                              .
    9 14.1   TOTAL NUMBER OF HYDROGEN BONDS OF TYPE O(I)-->H-N(I+3), SAME NUMBER PER 100 RESIDUES                              .
    6  9.4   TOTAL NUMBER OF HYDROGEN BONDS OF TYPE O(I)-->H-N(I+4), SAME NUMBER PER 100 RESIDUES                              .
    0  0.0   TOTAL NUMBER OF HYDROGEN BONDS OF TYPE O(I)-->H-N(I+5), SAME NUMBER PER 100 RESIDUES                              .
  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30     *** HISTOGRAMS OF ***           .
  0  0  0  0  0  0  0  1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0    RESIDUES PER ALPHA HELIX         .
  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0    PARALLEL BRIDGES PER LADDER      .
  0  0  0  0  1  1  1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0    ANTIPARALLEL BRIDGES PER LADDER  .
  1  1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0    LADDERS PER SHEET                .
  #  RESIDUE AA STRUCTURE BP1 BP2  ACC     N-H-->O    O-->H-N    N-H-->O    O-->H-N    TCO  KAPPA ALPHA  PHI   PSI    X-CA   Y-CA   Z-CA
    1    1 A M              0   0  196      0, 0.0     2,-0.1     0, 0.0    15,-0.0   0.000 360.0 360.0 360.0 -53.6    8.1   15.4   -1.5
    2    2 A A        -     0   0   50     14,-0.1    15,-3.4     1,-0.1    16,-0.4  -0.373 360.0-116.6 -78.0 172.7    9.2   18.8   -0.1
    3    3 A T  E     -A   16   0A  54     13,-0.3     2,-0.4    14,-0.1    13,-0.2  -0.714  11.8-147.1-114.5 162.6   10.6   19.0    3.4
    4    4 A V  E     -A   15   0A   2     11,-2.6    11,-2.4    -2,-0.3     2,-0.4  -0.993  12.9-155.0-120.9 137.2    9.5   20.7    6.7
END
      @dssp = BIPA::DSSP.new(test_str)
    end

    def test_return_size
      assert_equal(4, @dssp.sstruc.size)
    end

    def test_fist_residue
      assert_equal('', @dssp.sstruc['A1'])
    end

    def test_third_residue
      assert_equal('E', @dssp.sstruc['A3'])
    end

    def test_last_residue
      assert_equal('E', @dssp.sstruc['A4'])
    end
  end
end

