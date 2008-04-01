require File.dirname(__FILE__) + '/../test_helper'

class StructureTest < Test::Unit::TestCase
  
  should_have_many  :models
  
  should_have_many  :chains,
                    :through => :models
  
  should_have_many  :aa_chains,
                    :through => :models
  
  should_have_many  :na_chains,
                    :through => :models
                    
  should_have_many  :dna_chains,
                    :through => :models
                    
  should_have_many  :rna_chains,
                    :through => :models
  
  should_have_many  :hna_chains,
                    :through => :models
                    
  should_have_many  :het_chains,
                    :through => :models
                    
  should_have_many  :residues,
                    :through => :chains
                    
  should_have_many  :aa_residues,
                    :through    => :aa_chains

  should_have_many  :na_residues,
                    :through    => :na_chains

  should_have_many  :dna_residues,
                    :through    => :dna_chains

  should_have_many  :rna_residues,
                    :through    => :rna_chains
                    
  should_have_many  :hna_residues,
                    :through    => :hna_chains

  should_have_many  :het_residues,
                    :through    => :het_chains
                    
  should_have_many  :atoms,
                    :through    => :residues

  should_have_many  :aa_atoms,
                    :through    => :aa_residues

  should_have_many  :na_atoms,
                    :through    => :na_residues
                    
  should_have_many  :dna_atoms,
                    :through    => :dna_residues

  should_have_many  :rna_atoms,
                    :through    => :rna_residues

  should_have_many  :hna_atoms,
                    :through    => :hna_residues

  should_have_many  :het_atoms,
                    :through    => :het_residues

  should_have_many  :contacts,
                    :through    => :atoms

  should_have_many  :contacting_atoms,
                    :through    => :contacts

  should_have_many  :hbonds_as_donor,
                    :through    => :atoms

  should_have_many  :hbonds_as_acceptor,
                    :through    => :atoms

  should_have_many  :hbonding_donors,
                    :through    => :hbonds_as_acceptor

  should_have_many  :hbonding_acceptors,
                    :through    => :hbonds_as_donor

  should_have_many  :whbonds,
                    :through    => :atoms

  should_have_many  :whbonding_atoms,
                    :through    => :whbonds
                    

  context "A Stucture instance" do

    should "have correct models" do
      structure = Structure.new(valid_structure_params)
      model1    = Model.new(valid_model_params)
      model2    = Model.new(valid_model_params)

      structure.models << model1
      structure.models << model2

      assert structure.save

      assert_equal 2, structure.models.size
      assert_equal model1, structure.models[0]
      assert_equal model2, structure.models[1]
    end

    should "have correct chains" do
      structure = Structure.new(valid_structure_params)
      model     = Model.new(valid_model_params)
      chain1    = AaChain.new(valid_chain_params)
      chain2    = AaChain.new(valid_chain_params)

      structure.models << model
      structure.models.first.aa_chains << chain1
      structure.models.first.aa_chains << chain2

      assert structure.save

      assert_equal 2, structure.models.first.aa_chains.size
      assert_equal chain1, structure.models.first.aa_chains[0]
      assert_equal chain2, structure.models.first.aa_chains[1]

      assert_equal 2, structure.chains.size
      assert_equal chain1, structure.chains[0]
      assert_equal chain2, structure.chains[1]
    end

    should "have correct residues" do
      structure = Structure.new(valid_structure_params)
      model     = Model.new(valid_model_params)
      chain     = AaChain.new(valid_chain_params)
      residue1  = AaResidue.new(valid_residue_params)
      residue2  = AaResidue.new(valid_residue_params)

      structure.models << model
      structure.models.first.aa_chains << chain
      structure.models.first.aa_chains.first.residues << residue1
      structure.models.first.aa_chains.first.residues << residue2

      assert structure.save

      assert_equal 2, structure.models.first.aa_chains.first.residues.size
      assert_equal residue1, structure.models.first.aa_chains.first.residues[0]
      assert_equal residue2, structure.models.first.aa_chains.first.residues[1]

      assert_equal 2, structure.residues.size
      assert_equal residue1, structure.residues[0]
      assert_equal residue2, structure.residues[1]
    end

    should "have correct atoms" do
      structure = Structure.new(valid_structure_params)
      model     = Model.new(valid_model_params)
      chain     = AaChain.new(valid_chain_params)
      residue   = AaResidue.new(valid_residue_params)
      atom1     = Atom.new(valid_atom_params)
      atom2     = Atom.new(valid_atom_params)

      structure.models << model
      structure.models.first.chains << chain
      structure.models.first.chains.first.residues << residue
      structure.models.first.chains.first.residues.first.atoms << atom1
      structure.models.first.chains.first.residues.first.atoms << atom2

      assert structure.save

      assert_equal 2, structure.models.first.chains.first.residues.first.atoms.size
      assert_equal atom1, structure.models.first.chains.first.residues.first.atoms[0]
      assert_equal atom2, structure.models.first.chains.first.residues.first.atoms[1]

      assert_equal 2, structure.atoms.length
      assert_equal atom1, structure.atoms[0]
      assert_equal atom2, structure.atoms[1]
    end
  end
end
