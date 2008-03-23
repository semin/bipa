# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.0.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use (only works if using vendor/rails).
  # To use Rails without a database, you must remove the Active Record framework
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_bipa_session',
    :secret      => 'fe1264f4c08f2230f95658e3a5d976a9e1c4d24b23ad927cd9fb14a25724377b153b1e03480047969d9c563744bd7f48e0fec03e2d612f77d7966354abc73d63'
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
end

require "rubygems"
require "matrix"
require "fork_manager"
require "ar-extensions"
require "bio_extensions"
require "array_extensions"
require "vector_extensions"
require "math_extensions"
require "composite_primary_keys"
require "bipa"

# STI dependency
require_dependency "bipa/scop"
require_dependency "bipa/chain"
require_dependency "bipa/residue"
require_dependency "bipa/interface"
require_dependency "bipa/subfamily"

#
# BIPA environment
MAX_FORK        = ENV["MAX_FORK"].to_i > 0 ? ENV["MAX_FORK"].to_i : 2

PDB_SRC         = :remote
PDB_MIRROR_DIR  = "/BiO/Mirror/PDB"
PDB_ZIPPED_DIR  = "./data/structures/all/pdb"
PDB_ENTRY_FILE  = "./derived_data/pdb_entry_type.txt"
PDB_ENTRY_TYPE  = "prot-nuc"
PDB_DIR         = File.join(RAILS_ROOT, "/public/pdb")
PDB_FTP         = "ftp.ebi.ac.uk"
                
SCOP_DIR        = File.join(RAILS_ROOT, "/public/scop")
SCOP_URI        = "http//scop.mrc-lmb.cam.ac.uk/scop/parse/"
                
PRESCOP_DIR     = File.join(RAILS_ROOT, "/public/data/pre-scop")
PRESCOP_URI     = "http//www.mrc-lmb.cam.ac.uk/agm/pre-scop/parseable/"
                
NCBI_FTP        = "ftp.ncbi.nih.gov"
TAXONOMY_DIR    = File.join(RAILS_ROOT, "/public/taxonomy")
TAXONOMY_FTP    = "pub/taxonomy"

HBPLUS_DIR      = File.join(RAILS_ROOT, "/public/hbplus")
HBPLUS_BIN      = `which hbplus`
CLEAN_BIN       = `which clean`
                
NACCESS_DIR     = File.join(RAILS_ROOT, "/public/naccess")
NACCESS_BIN     = `which naccess`
NACCESS_VDW     = File.join(RAILS_ROOT, "/config/vdw.radii")
NACCESS_STD     = File.join(RAILS_ROOT, "/config/standard.data")

MAX_DISTANCE    = 5.0
MIN_INTRES_DASA = 1.0
MIN_SRFRES_SASA = 0.1
MIN_SRFRES_RASA = 0.05
MIN_INTATM_DASA = 0.1
MIN_SRFATM_SASA = 0.1

DSSP_DIR        = File.join(RAILS_ROOT, "/public/dssp")
DSSP_BIN        = `which dssp`

BATON_DIR       = File.join(RAILS_ROOT, "/public/baton")
SUBFAM_CUTOFF   = ENV["SUBFAM_CUTOFF"].to_i > 0 ? ENV["SUBFAM_CUTOFF"].to_i : 90

BLASTCLUST_DIR  = File.join(RAILS_ROOT, "/public/blastclust/")