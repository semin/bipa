# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  config.gem 'bio'
  config.gem 'narray'
  config.gem 'andand'
  config.gem 'hpricot'
  config.gem 'configatron'
  config.gem 'fork_manager'
  config.gem 'ar-extensions'
  config.gem 'composite_primary_keys'
  config.gem 'RubyInline', :lib => 'inline'
  config.gem 'googlecharts', :lib => 'gchart'

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
  # config.log_level = :warn

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
  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Uncomment to use default local time.
  config.time_zone = 'UTC'

  # for Action Mailer
#  config.action_mailer.delivery_method = :smtp
#  config.action_mailer.smtp_settings = {
#    :address        => "localhost",
#    :port           => 25,
#    :domain         => "localhost.localdomain",
#    :authentication => :login,
#  }
#  config.action_mailer.default_charset = "utf-8"
end

require 'matrix'
require 'bio_extensions'
require 'math_extensions'
require 'array_extensions'
require 'vector_extensions'
require 'kernel_extentions'
require 'string_extensions'
require 'struct_extensions'
require 'numeric_extensions'
require 'bipa'

# STI dependency
require_dependency 'scop'
require_dependency 'atom'
require_dependency 'chain'
require_dependency 'residue'
require_dependency 'interface'
require_dependency 'subfamily'
require_dependency 'alignment'
require_dependency 'go_relationship'
require_dependency 'gloria'
require_dependency 'mmcif'
require_dependency 'requiem'
require_dependency 'esst'
require_dependency 'fugue_hit'
require_dependency 'fugue_search'
require_dependency 'test_alignment'

# Environmental variables
ENV["PDB_EXT"] = ".pdb" # for Baton

# Configuration (Constants) for BIPA
configatron.rep_pids  = (100..100).step(10)
configatron.resume    = (ENV['RESUME'].to_i > 0    ? ENV['RESUME'].to_i    : false)
configatron.max_fork  = (ENV['MAX_FORK'].to_i > 0  ? ENV['MAX_FORK'].to_i  : 2)

configatron.epsilon                           = 1.0E-6
configatron.max_vdw_distance                  = 5.0
configatron.min_interface_residue_delta_asa   = 1.0
configatron.min_surface_residue_asa           = 0.1
configatron.min_surface_residue_relative_asa  = 0.07
configatron.min_interface_atom_delta_asa      = 0.1
configatron.min_surface_atom_asa              = 0.1

configatron.pdb_src         = :remote
configatron.pdb_mirror_dir  = "~/BiO/Mirror/PDB"
configatron.pdb_entry_file  = "./derived_data/pdb_entry_type.txt"
configatron.pdb_dir         = Rails.root.join("public/pdb")

configatron.scop_uri        = "http://scop.mrc-lmb.cam.ac.uk/scop/parse/"
configatron.scop_dir        = Rails.root.join("public/scop")
configatron.scop_pdb_dir    = "~/BiO/Store/SCOP/pdbstyle"
configatron.true_scop_classes = %w[a b c d e f g]

configatron.prescop_uri     = "http://www.mrc-lmb.cam.ac.uk/agm/pre-scop/parseable/"
configatron.prescop_dir     = Rails.root.join("public/pre-scop")

configatron.ncbi_ftp        = "ftp.ncbi.nih.gov"
configatron.taxonomy_ftp    = "pub/taxonomy"
configatron.taxonomy_dir    = Rails.root.join("public/taxonomy")

configatron.go_obo_uri      = "http://www.geneontology.org/ontology/gene_ontology_edit.obo"

configatron.hbplus_bin      = "~/BiO/Install/hbplus/hbplus"
configatron.clean_bin       = "~/BiO/Install/hbplus/clean"
configatron.hbadd_bin       = "~/BiO/Install/hbadd/hdadd"
configatron.hbplus_dir      = Rails.root.join("public/hbplus")

configatron.naccess_bin     = "~/BiO/Install/naccess/naccess"
configatron.naccess_vdw     = "~/BiO/Install/naccess/vdw.radii"
configatron.naccess_std     = "~/BiO/Install/naccess/standard.data"
configatron.naccess_dir     = Rails.root.join("public/naccess")

configatron.dssp_bin        = "~/BiO/Install/dssp/dsspcmbi"
configatron.dssp_dir        = Rails.root.join("public/dssp")

configatron.joy_bin         = "~/BiO/Install/joy/joy"
configatron.joy_dir         = Rails.root.join("public/joy")

configatron.baton_bin       = "~/BiO/Install/Baton/bin/Baton"
configatron.baton_dir       = Rails.root.join("public/baton")

configatron.blastclust_bin  = "/usr/bin/blastclust"
configatron.blastclust_dir  = Rails.root.join("public/blastclust/")

configatron.family_dir      = Rails.root.join("public/families")
configatron.alignment_dir   = Rails.root.join("public/alignments")
configatron.zap_dir         = Rails.root.join("public/zap")
configatron.spicoli_dir     = Rails.root.join("public/spicoli")
configatron.go_dir          = Rails.root.join("public/go")
configatron.esst_dir        = Rails.root.join("public/essts")
configatron.figure_dir      = Rails.root.join("public/figures")

configatron.astral40        = "~/BiO/Store/SCOP/scopseq/astral-scopdom-seqres-gd-sel-gs-bib-40-1.73.fa"
configatron.baliscore_bin   = "~/BiO/Install/bali_score/bali_score"
configatron.rel_url_root    = ActionController::Base.relative_url_root ? ActionController::Base.relative_url_root.to_s : ''

# for will_paginate plugin
WillPaginate.enable_named_scope

