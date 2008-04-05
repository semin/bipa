require File.dirname(__FILE__) + '/../test_helper'

class AtomTest < Test::Unit::TestCase
        
  include Bipa::Constants
        
  should_belong_to  :residue

  should_have_many  :contacts

  should_have_many  :contacting_atoms,
                    :through => :contacts

  should_have_many  :whbonds

  should_have_many  :whbonding_atoms,
                    :through => :whbonds
                    
  should_have_many  :hbonds_as_donor

  should_have_many  :hbonds_as_acceptor

  should_have_many  :hbonding_donors,
                    :through => :hbonds_as_acceptor

  should_have_many  :hbonding_acceptors,
                    :through => :hbonds_as_donor

  context "An Atom instance" do
    
    context "with a unbound ASA bigger than MIN_SRFATM_SASA threshold" do
      # MIN_SRFATM_SASA = 0.1
      should "be on surface" do
        atom = Atom.new
        atom.stubs(:unbound_asa).returns(10)
        assert atom.on_surface?
      end
    end
    
    context "with a unbound ASA smaller than MIN_SRFATM_SASA threshold" do
      
      should "not be on surface" do
        atom = Atom.new
        atom.stubs(:unbound_asa).returns(0.01)
        assert !atom.on_surface?
      end
    end
    
    context "with a delta ASA bigger than MIN_INTATM_DASA threshold" do
      # MIN_INTATM_DASA = 0.1
      
      should "be on interface" do
        atom = Atom.new(valid_atom_params)
        atom.stubs(:delta_asa).returns(0.2)
        assert atom.on_interface?
      end
    end
    
    context "belongs to an AaResidue" do

      should "respond to #aa?, #dna?, #rna?, and #na? correctly" do
        atom         = Atom.new(valid_atom_params)
        residue      = AaResidue.new(valid_residue_params)
        atom.residue = residue
        
        assert atom.aa?
        assert !atom.dna?
        assert !atom.rna?
        assert !atom.na?
        assert !atom.het?
      end
    end
    
    context "belongs to an DnaResidue" do
      
      should "correctly respond to #aa?, #dna?, #rna?, and #na? " do
        atom         = Atom.new(valid_atom_params)
        residue      = DnaResidue.new(valid_residue_params)
        atom.residue = residue
        
        assert !atom.aa?
        assert atom.dna?
        assert !atom.rna?
        assert atom.na?
        assert !atom.het?
      end
      
      should "correctly respond to #on_major_groove? and #on_minor_groove?" do

        NucleicAcids::Dna::Atoms::MAJOR_GROOVE.each do |residue, atoms|
          residue      = DnaResidue.new(valid_residue_params(:residue_name => residue))
          
          atoms.each do |atom|
            atom         = Atom.new(valid_atom_params(:atom_name => atom))
            atom.residue = residue
            assert atom.on_major_groove?
            assert !atom.on_minor_groove?
          end
        end
        
        NucleicAcids::Dna::Atoms::MINOR_GROOVE.each do |residue, atoms|
          residue      = DnaResidue.new(valid_residue_params(:residue_name => residue))
          
          atoms.each do |atom|
            atom         = Atom.new(valid_atom_params(:atom_name => atom))
            atom.residue = residue
            assert !atom.on_major_groove?
            assert atom.on_minor_groove?
          end
        end
      end
    end
    
    context "belongs to an RnaResidue" do
      
      should "respond to #aa?, #dna?, #rna?, and #na? correctly" do
        atom         = Atom.new(valid_atom_params)
        residue      = RnaResidue.new(valid_residue_params)
        atom.residue = residue
        atom.save
        
        assert !atom.aa?
        assert !atom.dna?
        assert atom.rna?
        assert atom.na?
        assert !atom.het?
      end
    end
    
    context "belongs to an HetResidue" do

      should "respond to #aa?, #dna?, #rna?, and #na? correctly" do
        atom         = Atom.new(valid_atom_params)
        residue      = HetResidue.new(valid_residue_params)
        atom.residue = residue
        
        assert !atom.aa?
        assert !atom.dna?
        assert !atom.rna?
        assert !atom.na?
        assert atom.het?
      end
    end
    
    should "be true when sending #polar? only it is a polar atom" do
      oxygen_atom     = Atom.new(valid_atom_params(:atom_name => "O1"))
      nitrogen_atom   = Atom.new(valid_atom_params(:atom_name => "N3"))
      non_polar_atom  = Atom.new(valid_atom_params(:atom_name => "C1"))
      
      assert oxygen_atom.polar?
      assert nitrogen_atom.polar?
      assert !non_polar_atom.polar?
    end
    
    should "return a correct PDB ATOM record when sending #to_pdb" do
      chain   = AaChain.new(:chain_code => "A")
      residue = AaResidue.new(:residue_name => "ILE",
                              :residue_code => 308)
      atom    = Atom.new( :atom_code => 2449,
                          :atom_name => "CD1",
                          :x => -25.003,
                          :y => 31.966,
                          :z => 77.389,
                          :occupancy => 1.00,
                          :tempfactor => 2.00,
                          :element => "C")
                          
      atom.residue  = residue
      residue.chain = chain
      
      assert_equal  "ATOM   2449  CD1 ILE A 308     -25.003  31.966  77.389  1.00  2.00           C  ",
                    atom.to_pdb
    end
    
    context "instanciated with :x, :y, and :z" do
      
      should "return a correct [x, y, z] when sending #xyz" do
        atom = Atom.new(valid_atom_params(:x => 1.1, :y => 2.2, :z => 3.3))
        assert_equal [1.1, 2.2, 3.3], atom.xyz
      end
      
      should "return a correct element of [x, y, z] when sending #dimension(i)" do
        atom = Atom.new(valid_atom_params(:x => 1.1, :y => 2.2, :z => 3.3))
        assert_equal 1.1, atom.dimension(0)
        assert_equal 2.2, atom.dimension(1)
        assert_equal 3.3, atom.dimension(2)
      end
      
      should "return a correct distance from other instance of Atom" do
        atom1 = Atom.new(valid_atom_params(:x => 1.1, :y => 2.2, :z => 3.3))
        atom2 = Atom.new(valid_atom_params(:x => 3.3, :y => 2.2, :z => 1.1))
        
        assert_equal Math.sqrt((1.1 - 3.3)**2 + (3.3 - 1.1)**2), atom1 - atom2
      end
    end
  end
end