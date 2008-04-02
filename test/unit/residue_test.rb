require File.dirname(__FILE__) + '/../test_helper'

class ResidueTest < Test::Unit::TestCase
  
  should_belong_to  :chain

  should_belong_to  :chain_interface

  should_have_many  :atoms

  should_have_many  :contacts,
                    :through => :atoms

  should_have_many  :contacting_atoms,
                    :through => :contacts

  should_have_many  :whbonds,
                    :through => :atoms

  should_have_many  :whbonding_atoms,
                    :through => :whbonds

  should_have_many  :hbonds_as_donor,
                    :through => :atoms

  should_have_many  :hbonds_as_acceptor,
                    :through => :atoms

  should_have_many  :hbonding_donors,
                    :through => :hbonds_as_acceptor

  should_have_many  :hbonding_acceptors,
                    :through => :hbonds_as_donor
  
end


class AaResidueTest < Test::Unit::TestCase
  
  should_belong_to  :domain

  should_belong_to  :domain_interface
  
  context "An AaResidue instance" do
    
    should "have correct one letter code when #one_letter_code" do
      AminoAcids::Residues::STANDARD.each do |aa|
        standard_aa = AaResidue.new(valid_residue_params(1, aa))
        assert_equal AminoAcids::Residues::ONE_LETTER_CODE[aa], standard_aa.one_letter_code
      end
    end
  
    should "raise Error when it is non-standard amino acid when #one_letter_code" do
      non_standard_aa = AaResidue.new(valid_residue_params(1, "HEL"))
      assert_raise(RuntimeError) { non_standard_aa.one_letter_code }
    end
  end
end
