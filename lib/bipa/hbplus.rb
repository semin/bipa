require "rubygems"
require "active_support"
require File.expand_path(File.dirname(__FILE__) + "/constants")

module Bipa
  class Hbplus

    attr_reader :hbonds, :whbonds

    class Atom

      include Bipa::Constants

      attr_reader :chain_code,
                  :residue_code,
                  :insertion_code,
                  :residue_name,
                  :atom_name

      def initialize(chain_code,
                     residue_code,
                     insertion_code,
                     residue_name,
                     atom_name)

        @chain_code     = chain_code == "-" ? nil : chain_code
        @residue_code   = residue_code
        @insertion_code = insertion_code == "-" ? nil : insertion_code
        @residue_name   = residue_name
        @atom_name      = atom_name
      end

      def water?
        @residue_name == "HOH"
      end

      def dna?
        NucleicAcids::Dna::Residues::ALL.include?(@residue_name)
      end

      def rna?
        NucleicAcids::Rna::Residues::ALL.include?(@residue_name)
      end

      def na?
        dna? || rna?
      end

      def aa?
        AminoAcids::Residues::STANDARD.include?(@residue_name)
      end

      def ==(other)
        raise "Cannot compare to #{other.class} type!" unless other.kind_of?(Bipa::Hbplus::Atom)
        return  @chain_code == other.chain_code &&
                @residue_code == other.residue_code &&
                @insertion_code == other.insertion_code &&
                @residue_name == other.residue_name &&
                @atom_name == other.atom_name
      end

      def to_s
        "#{@chain_code}:#{@residue_code}:#{@insertion_code}:#{@residue_name}:#{@atom_name}"
      end
    end

    Hbond   = Struct.new("Hbond",
                         :donor,
                         :acceptor,
                         :da_distance,
                         :category,
                         :gap,
                         :ca_distance,
                         :dha_angle,
                         :ha_distance,
                         :haaa_angle,
                         :daaa_angle,
                         :hbond_code)

    WHbond  = Struct.new("WHbond",
                         :aa_atom,
                         :na_atom,
                         :water_atom)

    def initialize(file_str)

      @hbonds = []

      file_str.each do |line|
        if line[15..15] =~ /\d+/
          hbline = Hbplus.parse_hbplus_line(line)
          @hbonds <<  Hbond.new(Atom.new(hbline[:donor_chain_code],
                                        hbline[:donor_residue_code],
                                        hbline[:donor_insertion_code],
                                        hbline[:donor_residue_name],
                                        hbline[:donor_atom_name]),
                                Atom.new(hbline[:acceptor_chain_code],
                                        hbline[:acceptor_residue_code],
                                        hbline[:acceptor_insertion_code],
                                        hbline[:acceptor_residue_name],
                                        hbline[:acceptor_atom_name]),
                                hbline[:da_distance],
                                hbline[:category],
                                hbline[:gap],
                                hbline[:ca_distance],
                                hbline[:dha_angle],
                                hbline[:ha_distance],
                                hbline[:haaa_angle],
                                hbline[:daaa_angle],
                                hbline[:hbond_code])
        end
      end

      aa_neighbors = {}
      na_neighbors = {}

      hbonds.each do |hbond|
        if hbond.donor.water? && hbond.acceptor.aa?
          aa_neighbors[hbond.donor.to_s] = [] if aa_neighbors[hbond.donor.to_s].nil?
          aa_neighbors[hbond.donor.to_s] << hbond.acceptor.to_s
        elsif hbond.donor.aa? && hbond.acceptor.water?
          aa_neighbors[hbond.acceptor.to_s] = [] if aa_neighbors[hbond.acceptor.to_s].nil?
          aa_neighbors[hbond.acceptor.to_s] << hbond.donor.to_s
        elsif hbond.donor.water? && hbond.acceptor.na?
          na_neighbors[hbond.donor.to_s] = [] if na_neighbors[hbond.donor.to_s].nil?
          na_neighbors[hbond.donor.to_s] << hbond.acceptor.to_s
        elsif hbond.donor.na? && hbond.acceptor.water?
          na_neighbors[hbond.acceptor.to_s] = [] if na_neighbors[hbond.acceptor.to_s].nil?
          na_neighbors[hbond.acceptor.to_s] << hbond.donor.to_s
        end
      end

      @whbonds = []

      water_bridges = aa_neighbors.keys & na_neighbors.keys

      water_bridges.each do |water|
        aa_neighbors[water].each do |aa|
          na_neighbors[water].each do |na|
            @whbonds << WHbond.new(Atom.new(*aa.split(/:/)),
                                   Atom.new(*na.split(/:/)),
                                   Atom.new(*water.split(/:/)))
          end
        end
      end
    end

    def self.parse_hbplus_line(line)
      hbline = {}

      hbline[:donor_chain_code]         = line[0..0]
      hbline[:donor_residue_code]       = line[1..4].to_i
      hbline[:donor_insertion_code]     = line[5..5]
      hbline[:donor_residue_name]       = line[6..8].strip
      hbline[:donor_atom_name]          = line[9..12].strip
      hbline[:acceptor_chain_code]      = line[14..14]
      hbline[:acceptor_residue_code]    = line[15..18].to_i
      hbline[:acceptor_insertion_code]  = line[19..19]
      hbline[:acceptor_residue_name]    = line[20..22].strip
      hbline[:acceptor_atom_name]       = line[23..26].strip
      hbline[:da_distance]              = line[27..31].to_f
      hbline[:category]                 = line[33..34]
      hbline[:gap]                      = line[36..38].to_f < 0 ? nil : line[36..38].to_f
      hbline[:ca_distance]              = line[40..44].to_f < 0 ? nil : line[40..44].to_f
      hbline[:dha_angle]                = line[46..50].to_f < 0 ? nil : line[46..50].to_f
      hbline[:ha_distance]              = line[52..56].to_f < 0 ? nil : line[52..56].to_f
      hbline[:haaa_angle]               = line[58..62].to_f < 0 ? nil : line[58..62].to_f
      hbline[:daaa_angle]               = line[64..68].to_f < 0 ? nil : line[64..68].to_f
      hbline[:hbond_code]               = line[70..74].to_i
      hbline
    end
  end # class Hbplus
end # module Bipa

if $0 == __FILE__
  require "test/unit"

  include Bipa

  class TestHbplus < Test::Unit::TestCase

    def setup
@test_str = <<END
Hbplus Hydrogen Bond Calculator v 3.15            May 03 11:00:02 BST 2007
(c) I McDonald, D Naylor, D Jones and J Thornton 1993 All Rights Reserved.
  Citing Hbplus in publications that use these results is condition of use.
  1EFW <- Brookhaven Code "pdb1efw.new" <- PDB file
<---DONOR---> <-ACCEPTOR-->    atom                        ^               
c    i                          cat <-CA-CA->   ^        H-A-AA   ^      H- 
  h    n   atom  resd res      DA  || num        DHA   H-A  angle D-A-AA Bond
n    s   type  num  typ     dist DA aas  dist angle  dist       angle   num
-2032-HOH O   A0001-MET O   3.42 HM  -2 -1.00  -1.0 -1.00  -1.0 151.2     1
A0002-ARG NE  B0249-ASP OD1 3.01 SS  -1  9.22 118.2  2.40  97.3 108.9     2
A0003-ARG NH1 B0213-ASP OD2 2.75 SS  -1 11.31 110.0  2.25 126.3 132.4     3
A0004-THR N   A0020-VAL O   3.00 MM  16  5.39 124.0  2.32 172.4 156.8     4
A0004-THR OG1 A0005-HIS ND1 2.40 SS   1  3.74 137.6  1.56 126.3 108.1     5
A0005-HIS ND1 A0004-THR OG1 2.40 SS   1  3.74 136.0  1.58 147.1 136.1     6
-2024-HOH O   A0005-HIS O   2.86 HM  -2 -1.00  -1.0 -1.00  -1.0 149.8     7
A0005-HIS NE2 -2041-HOH O   2.78 SH  -2 -1.00 136.5  1.97  -1.0  -1.0     8
-2041-HOH O   A0005-HIS NE2 2.78 HS  -2 -1.00  -1.0 -1.00  -1.0 104.7     9
A0009-SER N   A0006-TYR O   2.87 MM   3  5.48 169.4  1.89 132.5 132.1    10
A0009-SER OG  A0006-TYR O   2.81 SM   3  5.48 164.4  1.84 129.2 126.8    11
A0006-TYR OH  B0213-ASP OD2 2.37 SS  -1  9.06 132.4  1.58  99.6 117.4    12
A0007-ALA N   A0041-ASP OD2 2.21 MS  34  6.00 105.8  1.72 168.2 151.7    13
A0007-ALA N   -2024-HOH O   2.81 MH  -2 -1.00 134.4  2.02  -1.0  -1.0    14
-2015-HOH O   A0008-GLY O   3.38 HM  -2 -1.00  -1.0 -1.00  -1.0 107.9    15
-2075-HOH O   A0009-SER O   2.83 HM  -2 -1.00  -1.0 -1.00  -1.0 139.4    16
A0011-ARG NE  A0010-LEU O   2.71 SM   1  3.74 174.1  1.71 122.9 121.7    17
A0058-ARG NH1 C0006- DT O2  2.96 SH  -2 -1.00 160.0  2.00  -1.0  -1.0    18
END
    end

    def test_parse_hbplus_line
      test_line = "-2015-HOH O   A0008-GLY O   3.38 HM  -2 -1.00  -1.0 -1.00  -1.0 107.9    15"
      hbline = Hbplus.parse_hbplus_line(test_line)
      assert_equal("-",     hbline[:donor_chain_code])
      assert_equal(2015,    hbline[:donor_residue_code])
      assert_equal("-",     hbline[:donor_insertion_code])
      assert_equal("HOH",   hbline[:donor_residue_name])
      assert_equal("O",     hbline[:donor_atom_name])
      assert_equal("A",     hbline[:acceptor_chain_code])
      assert_equal(8,       hbline[:acceptor_residue_code])
      assert_equal("-",     hbline[:acceptor_insertion_code])
      assert_equal("GLY",   hbline[:acceptor_residue_name])
      assert_equal("O",     hbline[:acceptor_atom_name])
      assert_equal(3.38,    hbline[:da_distance])
      assert_equal("HM",    hbline[:category])
      assert_equal(nil,     hbline[:gap])
      assert_equal(nil,     hbline[:ca_distance])
      assert_equal(nil,     hbline[:dha_angle])
      assert_equal(nil,     hbline[:ha_distance])
      assert_equal(nil,     hbline[:haaa_angle])
      assert_equal(107.9,   hbline[:daaa_angle])
      assert_equal(15,      hbline[:hbond_code])
    end

    def test_parse_multiple_hbplus_lines_with_headers
      hbplus = Hbplus.new(@test_str)
      assert_equal(18, hbplus.hbonds.size)
      assert_equal(2032, hbplus.hbonds.first.donor.residue_code)
    end

    def test_aa?
      hbplus = Hbplus.new(@test_str)
      assert(hbplus.hbonds[0].acceptor.aa?)
    end

    def test_dna?
      hbplus = Hbplus.new(@test_str)
      assert(hbplus.hbonds[17].acceptor.dna?)
    end

    def test_rna?
    end

    def test_na?
      hbplus = Hbplus.new(@test_str)
      assert(hbplus.hbonds[17].acceptor.na?)
    end

    def test_water?
      hbplus = Hbplus.new(@test_str)
      assert(hbplus.hbonds[0].donor.water?)
    end

    def test_equality_between_atoms
      atom1 = Hbplus::Atom.new("A", "1", nil, "GLY", "O")
      atom2 = Hbplus::Atom.new("A", "1", nil, "GLY", "O")
      atom3 = Hbplus::Atom.new("A", "1", "A", "GLY", "O")

      assert_equal(atom1, atom2)
      assert_not_equal(atom1, atom3)
      assert_raise RuntimeError do
        atom1 == 1
      end
    end

    def test_water_mediated_hbonds
hbplus_str = <<END
Hbplus Hydrogen Bond Calculator v 3.15            May 03 11:00:02 BST 2007
(c) I McDonald, D Naylor, D Jones and J Thornton 1993 All Rights Reserved.
  Citing Hbplus in publications that use these results is condition of use.
  1EFW <- Brookhaven Code "pdb1efw.new" <- PDB file
<---DONOR---> <-ACCEPTOR-->    atom                        ^               
c    i                          cat <-CA-CA->   ^        H-A-AA   ^      H- 
  h    n   atom  resd res      DA  || num        DHA   H-A  angle D-A-AA Bond
n    s   type  num  typ     dist DA aas  dist angle  dist       angle   num
-2032-HOH O   A0001-MET O   3.42 HM  -2 -1.00  -1.0 -1.00  -1.0 151.2     1
A0002- DA NE  -2032-HOH O   3.01 SS  -1  9.22 118.2  2.40  97.3 108.9     2
A0003- DG NH1 -2032-HOH O   2.75 SS  -1 11.31 110.0  2.25 126.3 132.4     3
END
      whbonds = Hbplus.new(hbplus_str).whbonds
      assert_equal(2, whbonds.size)
    end
  end
end
