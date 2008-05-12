require "rubygems"
require "simple_memoize"

require "matrix"
require "inline"
require "has_finder"
require "fork_manager"
require "will_paginate"
require "ar-extensions"
require "composite_primary_keys"

require "bio_extensions"
require "array_extensions"
require "vector_extensions"
require "math_extensions"
require "active_record_extensions"

require "bipa"

# STI dependency
require_dependency "scop"
require_dependency "atom"
require_dependency "chain"
require_dependency "residue"
require_dependency "interface"
require_dependency "subfamily"
require_dependency "alignment"
require_dependency "go_relationship"
require_dependency "gloria"
require_dependency "mmcif"

# Constants for BIPA
RESUME          = ENV["RESUME"].to_i > 0    ? ENV["RESUME"].to_i    : false
MAX_FORK        = ENV["MAX_FORK"].to_i > 0  ? ENV["MAX_FORK"].to_i  : 2

EPSILON                           = 1.0E-6
MAX_VDW_DISTANCE                  = 5.0
MIN_INTERFACE_RESIDUE_DELTA_ASA   = 1.0
MIN_SURFACE_RESIDUE_ASA           = 0.1
MIN_SURFACE_RESIDUE_RELATIVE_ASA  = 0.05
MIN_INTERFACE_ATOM_DELTA_ASA      = 0.1
MIN_SURFACE_ATOM_ASA              = 0.1

PDB_SRC         = :remote
PDB_MIRROR_DIR  = "/BiO/Mirror/PDB"
PDB_ENTRY_FILE  = "./derived_data/pdb_entry_type.txt"
PDB_DIR         = File.join(RAILS_ROOT, "/public/pdb")

SCOP_URI        = "http://scop.mrc-lmb.cam.ac.uk/scop/parse/"
SCOP_DIR        = File.join(RAILS_ROOT, "/public/scop")
SCOP_PDB_DIR    = "/BiO/Store/SCOP/pdbstyle"

PRESCOP_URI     = "http://www.mrc-lmb.cam.ac.uk/agm/pre-scop/parseable/"
PRESCOP_DIR     = File.join(RAILS_ROOT, "/public/pre-scop")

NCBI_FTP        = "ftp.ncbi.nih.gov"
TAXONOMY_FTP    = "pub/taxonomy"
TAXONOMY_DIR    = File.join(RAILS_ROOT, "/public/taxonomy")

CLEAN_BIN       = `which clean`.chomp
HBADD_BIN       = `which hbadd`.chomp
HBPLUS_BIN      = `which hbplus`.chomp
HBPLUS_DIR      = File.join(RAILS_ROOT, "/public/hbplus")
HET_DICT_FILE   = "/BiO/Mirror/PDB/data/monomers/het_dictionary.txt"

NACCESS_BIN     = `which naccess`.chomp
NACCESS_VDW     = "/BiO/Install/naccess/vdw.radii"
NACCESS_STD     = "/BiO/Install/naccess/standard.data"
NACCESS_DIR     = File.join(RAILS_ROOT, "/public/naccess")

DSSP_BIN        = `which dssp`.chomp
DSSP_DIR        = File.join(RAILS_ROOT, "/public/dssp")

JOY_BIN         = `which joy`.chomp
JOY_DIR         = File.join(RAILS_ROOT, "/public/joy")

BATON_BIN       = `which Baton`.chomp
BATON_DIR       = File.join(RAILS_ROOT, "/public/baton")

BLASTCLUST_BIN  = `which blastclust`.chomp
BLASTCLUST_DIR  = File.join(RAILS_ROOT, "/public/blastclust/")

FAMILY_DIR      = File.join(RAILS_ROOT, "/public/families")
ZAP_DIR         = File.join(RAILS_ROOT, "/public/zap")

GO_DIR          = File.join(RAILS_ROOT, "/public/go")
