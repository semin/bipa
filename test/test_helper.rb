ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
require 'mocha'

class Test::Unit::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually 
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  # fixtures :all

  # Add more helper methods to be used by all tests here...
  
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
end
