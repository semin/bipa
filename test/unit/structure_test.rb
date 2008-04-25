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
                                      

  context "A Stucture instance" do

    should "have correct models" do
      structure = Structure.create(valid_structure_params)
      model1    = Model.create(valid_model_params)
      model2    = Model.create(valid_model_params)

      structure.models << model1
      structure.models << model2

      assert structure.save

      assert_equal 2, structure.models.size
      assert structure.models.include?(model1)
      assert structure.models.include?(model2)
    end

    should "have correct chains" do
      structure = Structure.create(valid_structure_params)
      model     = Model.create(valid_model_params)
      chain1    = AaChain.create(valid_chain_params(:chain_code => "A"))
      chain2    = AaChain.create(valid_chain_params(:chain_code => "B")) 

      structure.models << model
      structure.models.first.aa_chains << chain1
      structure.models.first.aa_chains << chain2

      assert structure.save

      assert_equal 2, structure.models.first.aa_chains.size
      assert structure.models.first.aa_chains.include?(chain1)
      assert structure.models.first.aa_chains.include?(chain2)

      assert_equal 2, structure.aa_chains.size
      assert structure.aa_chains.include?(chain1)
      assert structure.aa_chains.include?(chain2)
    end

    should "have correct residues" do
      structure = Structure.create(valid_structure_params)
      model     = Model.create(valid_model_params)
      chain     = AaChain.create(valid_chain_params)
      residue1  = AaResidue.create(valid_residue_params)
      residue2  = AaResidue.create(valid_residue_params)

      structure.models << model
      structure.models.first.aa_chains << chain
      structure.models.first.aa_chains.first.residues << residue1
      structure.models.first.aa_chains.first.residues << residue2

      assert structure.save

      assert_equal 2, structure.models.first.aa_chains.first.residues.size
      assert structure.models.first.aa_chains.first.residues.include?(residue1)
      assert structure.models.first.aa_chains.first.residues.include?(residue2)

      assert_equal 2, structure.residues.size
      assert structure.residues.include?(residue1)
      assert structure.residues.include?(residue2)
    end

    should "have correct atoms" do
      structure = Structure.create(valid_structure_params)
      model     = Model.create(valid_model_params)
      chain     = AaChain.create(valid_chain_params)
      residue   = AaResidue.create(valid_residue_params)
      atom1     = StdAtom.create(valid_atom_params)
      atom2     = StdAtom.create(valid_atom_params)
    
      structure.models << model
      structure.models.first.aa_chains << chain
      structure.models.first.aa_chains.first.residues << residue
      structure.models.first.aa_chains.first.residues.first.atoms << atom1
      structure.models.first.aa_chains.first.residues.first.atoms << atom2
    
      assert structure.save
    
      assert_equal 2, structure.models.first.aa_chains.first.residues.first.atoms.size
      assert structure.models.first.aa_chains.first.residues.first.atoms.include?(atom1)
      assert structure.models.first.aa_chains.first.residues.first.atoms.include?(atom2)
    
      assert_equal 2, structure.atoms.size
      assert structure.atoms.include?(atom1)
      assert structure.atoms.include?(atom2)
    end
  end
end
