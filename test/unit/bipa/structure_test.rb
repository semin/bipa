require File.dirname(__FILE__) + '/../../test_helper'

class Bipa::StructureTest < Test::Unit::TestCase
  
  include Bipa::Constants
  
  # Dummy parameters for models
  def valid_structure_params
    {
      :pdb_code       => "10mh",
      :exp_method     => "X-ray",
      :classification => "protein-DNA",
      :deposited_at   => "1998-10-12"
    }
  end
  
  def valid_model_params(model_code = nil)
    {
      :model_code     => model_code || rand(100)
    }
  end
  
  def valid_chain_params(chain_code = nil)
    alphabets = ("a".."z").to_a + ("A".."Z").to_a
    {
      :chain_code     => chain_code || alphabets[rand(alphabets.size)]
    }
  end
  
  def valid_residue_params(residue_code = nil,
                           residue_name = nil,
                           type = nil)
                           
    residue_names = AminoAcids::Residues::STANDARD +
                    NucleicAcids::Residues::STANDARD
    residue_types = Bipa::Residue.send(:subclasses).map(&:to_s)
    
    {
      :residue_code => residue_code || rand(100),
      :residue_name => residue_name || residue_names[rand(residue_names.size)],
      :type         => type || residue_types[rand(residue_types.size)]
    }
  end
  
  def valid_atom_params(atom_code = nil,
                        atom_name = nil,
                        x = nil, y = nil, z = nil)
    
    atom_names =  AminoAcids::Atoms::BACKBONE + 
                  NucleicAcids::Atoms::PHOSPHATE +
                  NucleicAcids::Atoms::SUGAR
                  
    {
      :atom_code  => atom_code || rand(1000),
      :atom_name  => atom_name || atom_names[rand(atom_names.size)],
      :x          => x || rand(0) + rand(100),
      :y          => y || rand(0) + rand(100),
      :z          => z || rand(0) + rand(100)
    }
  end
  
  
  # Tests
  def test_models
    structure = Bipa::Structure.new(valid_structure_params)
    model1    = Bipa::Model.new(valid_model_params)
    model2    = Bipa::Model.new(valid_model_params)
    
    structure.models << model1
    structure.models << model2

    assert structure.save
    
    assert_equal 2, structure.models.size
    assert_equal model1, structure.models[0]
    assert_equal model2, structure.models[1]
  end 
  
  def test_chains
    structure = Bipa::Structure.new(valid_structure_params)
    model     = Bipa::Model.new(valid_model_params)
    chain1    = Bipa::Chain.new(valid_chain_params)
    chain2    = Bipa::Chain.new(valid_chain_params)
    
    structure.models << model
    structure.models.first.chains << chain1
    structure.models.first.chains << chain2
  
    assert structure.save
    
    assert_equal 2, structure.models.first.chains.size
    assert_equal chain1, structure.models.first.chains[0]
    assert_equal chain2, structure.models.first.chains[1]
    
    assert_equal 2, structure.chains.size
    assert_equal chain1, structure.chains[0]
    assert_equal chain2, structure.chains[1]
  end
  
  def test_residues
    structure = Bipa::Structure.new(valid_structure_params)
    model     = Bipa::Model.new(valid_model_params)
    chain     = Bipa::Chain.new(valid_chain_params)
    residue1  = Bipa::AaResidue.new(valid_residue_params)
    residue2  = Bipa::AaResidue.new(valid_residue_params)
    
    structure.models << model
    structure.models.first.chains << chain
    structure.models.first.chains.first.residues << residue1
    structure.models.first.chains.first.residues << residue2
    
    assert structure.save
    
    assert_equal 2, structure.models.first.chains.first.residues.size
    assert_equal residue1, structure.models.first.chains.first.residues[0]
    assert_equal residue2, structure.models.first.chains.first.residues[1]
    
    assert_equal 2, structure.residues.size
    assert_equal residue1, structure.residues[0]
    assert_equal residue2, structure.residues[1]
  end
  
  def test_atoms
    structure = Bipa::Structure.new(valid_structure_params)
    model     = Bipa::Model.new(valid_model_params)
    chain     = Bipa::Chain.new(valid_chain_params)
    residue   = Bipa::AaResidue.new(valid_residue_params)
    atom1     = Bipa::Atom.new(valid_atom_params)
    atom2     = Bipa::Atom.new(valid_atom_params)
    
    structure.models << model
    structure.models.first.chains << chain
    structure.models.first.chains.first.residues << residue
    structure.models.first.chains.first.residues.first.atoms << atom1
    structure.models.first.chains.first.residues.first.atoms << atom2
    
    assert structure.save
    
    assert_equal 2, structure.models.first.chains.first.residues.first.atoms.size
    assert_equal atom1, structure.models.first.chains.first.residues.first.atoms[0]
    assert_equal atom2, structure.models.first.chains.first.residues.first.atoms[1]
    
    assert_equal 2, structure.atoms.size
    assert_equal atom1, structure.atoms[0]
    assert_equal atom2, structure.atoms[1]
  end
end