ENV["RAILS_ENV"] = "test"

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
require 'mocha'

require_dependency "scop"
require_dependency "chain"
require_dependency "residue"
require_dependency "interface"
require_dependency "subfamily"

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
  def random_alphabet(count = 1)
    result = ""
    alphabets = ("a".."z").to_a + ("A".."Z").to_a
    count.times { result += alphabets[rand(alphabets.size)] }
    result
  end
  
  def random_number(digit = 1)
    eval("rand(1E#{digit})").to_i
  end
  
  def random_pdb_code
    random_number(2).to_s + random_alphabet(2)
  end
  
  def valid_structure_params(opts = {})
    {
      :pdb_code       => random_pdb_code,
      :exp_method     => "X-ray",
      :classification => "protein-DNA",
      :deposited_at   => "1998-10-12"
    }.merge!(opts)
  end
  
  def valid_model_params(opts = {})
    {
      :model_code     => rand(100)
    }.merge!(opts)
  end
  
  def valid_chain_params(opts = {})
    {
      :model_id       => random_number(5),
      :chain_code     => random_alphabet
    }.merge!(opts)
  end
  
  def valid_residue_params(opts = {})
                           
    residue_names = AminoAcids::Residues::STANDARD +
                    NucleicAcids::Residues::STANDARD
    
    {
      :residue_code => rand(100),
      :residue_name => residue_names[rand(residue_names.size)]
    }.merge!(opts)
  end
  
  def valid_atom_params(opts = {})
    
    atom_names =  AminoAcids::Atoms::BACKBONE + 
                  NucleicAcids::Atoms::PHOSPHATE +
                  NucleicAcids::Atoms::SUGAR
                  
    {
      :atom_code  => rand(1000),
      :atom_name  => atom_names[rand(atom_names.size)],
      :x          => rand(0) + rand(100),
      :y          => rand(0) + rand(100),
      :z          => rand(0) + rand(100)
    }.merge!(opts)
  end
end
