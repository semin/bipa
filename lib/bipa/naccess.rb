module Bipa
  class Naccess
    
    attr_reader :atom_asa

    def initialize(file_str)
      @atom_asa = {}
      file_str.each do |line|
        if line =~ /^ATOM/
          atom_asa[line[6..10].to_i] = line[54..61].to_f
        end
      end
      @atom_asa
    end
  end
end


if $0 == __FILE__
  require 'test/unit'
  
  class TestNaccess < Test::Unit::TestCase
    
    def setup
      test_str = <<END
ATOM      1  N   VAL A  33       6.401  -0.502  39.397  38.898  1.65
ATOM      2  CA  VAL A  33       7.461   0.365  39.994  12.471  1.87
ATOM      3  C   VAL A  33       6.871   1.488  40.870   2.082  1.76
ATOM      4  O   VAL A  33       7.522   1.932  41.817   5.448  1.40
ATOM      5  CB  VAL A  33       8.373   0.976  38.914   8.438  1.87
ATOM      6  CG1 VAL A  33       9.411   1.873  39.540  10.450  1.87
ATOM      7  CG2 VAL A  33       9.055  -0.115  38.111  62.293  1.87
ATOM      8  N   ILE A  34       5.732   2.053  40.482   3.262  1.65
ATOM      9  CA  ILE A  34       5.028   3.019  41.326   0.000  1.87
ATOM     10  C   ILE A  34       3.653   2.511  41.633   0.000  1.76
END
      @naccess = Bipa::Naccess.new(test_str)
    end

    def test_return_size
      assert_equal(@naccess.atom_asa.size, 10)
    end

    def test_first_residue
      assert_equal(@naccess.atom_asa[1], 38.898)
    end

    def test_last_residue
      assert_equal(@naccess.atom_asa[10], 0.000)
    end
  end
end

