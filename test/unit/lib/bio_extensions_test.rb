require File.dirname(__FILE__) + '/../../test_helper'

class BioExtensionsTest < Test::Unit::TestCase
  
  include Bipa::Constants
          
  context "A Bio::PDB instantiated with 10mh.pdb" do
    
    setup do
      @pdb = Bio::PDB.new(IO.read(File.dirname(__FILE__) + "/10mh.pdb"))
    end
  
    should "have a correct deposition date" do
      assert_equal "10-AUG-1998", @pdb.deposition_date
    end
  
    should "have a correct resolution" do
      assert_equal 2.55, @pdb.resolution
    end
  
    should "have a correct experimental method" do
      assert_equal "X-RAY DIFFRACTION", @pdb.exp_method
    end
  
    context "having a Bio::PDB::Model instance" do

      should "have correct amino acid chains" do
        assert_equal 1,   @pdb.models.first.aa_chains.size
        assert_equal "A", @pdb.models.first.aa_chains.first.id
      end

      should "have correct nucleic acid chains" do
        assert_equal 2,   @pdb.models.first.na_chains.size
        assert_equal "B", @pdb.models.first.na_chains[0].id
        assert_equal "C", @pdb.models.first.na_chains[1].id
      end
    end
    
    context "having a Bio::PDB::Chain instance" do
      
      should "be true when sending #aa? to amino acid chain" do
        assert @pdb.models.first.chains[0].aa?
      end
      
      should "be false when sending other than #aa? to amino acid chain" do
        assert !@pdb.models.first.chains[0].na?
        assert !@pdb.models.first.chains[0].dna?
        assert !@pdb.models.first.chains[0].rna?
        assert !@pdb.models.first.chains[0].hna?
      end
      
      should "be true when sending #na? to NA chain" do
        assert @pdb.models.first.chains[1].na?
      end
      
      should "be true when sending #dna? to DNA chain" do
        assert @pdb.models.first.chains[1].dna?
      end
      
      should "be true when sending other than #dna? to DNA chain" do
        assert !@pdb.models.first.chains[1].aa?
        assert !@pdb.models.first.chains[1].rna?
        assert !@pdb.models.first.chains[1].hna?
      end
    end
    
    context "having a Bio::PDB::Residue instance" do
      
      should "be true when sending #aa? to amino acid residues" do
        AminoAcids::Residues::STANDARD.each do |aa|
          residue = Bio::PDB::Residue.new
          residue.stubs(:resName).returns(aa)
          assert residue.aa?
        end
      end
      
      should "be false when sending other than #aa? to amino acid residues" do
        AminoAcids::Residues::STANDARD.each do |aa|
          residue = Bio::PDB::Residue.new
          residue.stubs(:resName).returns(aa)
          assert !residue.na?
          assert !residue.dna?
          assert !residue.rna?
        end
      end
      
      should "be true when sending #na? to nucleic acid residues" do
        NucleicAcids::Residues::ALL.each do |na|
          residue = Bio::PDB::Residue.new
          residue.stubs(:resName).returns(na)
          assert residue.na?
        end
      end
      
      should "be false when sending other than #na? to nucleic acid residues" do
        NucleicAcids::Residues::ALL.each do |na|
          residue = Bio::PDB::Residue.new
          residue.stubs(:resName).returns(na)
          assert !residue.aa?
        end
      end
      
      should "be true when sending #dna? to DNA residues" do
        NucleicAcids::Dna::Residues::ALL.each do |dna|
          residue = Bio::PDB::Residue.new
          residue.stubs(:resName).returns(dna)
          assert residue.dna?
        end
      end
      
      should "be false when sending other than #dna? to DNA residues" do
        NucleicAcids::Dna::Residues::ALL.each do |dna|
          residue = Bio::PDB::Residue.new
          residue.stubs(:resName).returns(dna)
          assert !residue.aa?
          assert !residue.rna?
        end
      end
      
      should "be true when sending #rna? to RNA residues" do
        NucleicAcids::Rna::Residues::ALL.each do |rna|
          residue = Bio::PDB::Residue.new
          residue.stubs(:resName).returns(rna)
          assert residue.rna?
        end
      end
      
      should "be false when sending other than #rna? to RNA residues" do
        NucleicAcids::Rna::Residues::ALL.each do |rna|
          residue = Bio::PDB::Residue.new
          residue.stubs(:resName).returns(rna)
          assert !residue.aa?
          assert !residue.dna?
        end
      end
    end
  end
end