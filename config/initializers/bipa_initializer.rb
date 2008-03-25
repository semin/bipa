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

# Constants for BIPA
RESUME          = ENV["RESUME"].to_i > 0 ? ENV["RESUME"].to_i : false
MAX_FORK        = ENV["MAX_FORK"].to_i > 0 ? ENV["MAX_FORK"].to_i : 2

PDB_SRC         = :remote
PDB_MIRROR_DIR  = "/BiO/Mirror/PDB"
PDB_ENTRY_FILE  = "./derived_data/pdb_entry_type.txt"
PDB_DIR         = File.join(RAILS_ROOT, "/public/pdb")

SCOP_URI        = "http://scop.mrc-lmb.cam.ac.uk/scop/parse/"
SCOP_DIR        = File.join(RAILS_ROOT, "/public/scop")

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

MAX_DISTANCE    = 5.0
MIN_INTRES_DASA = 1.0
MIN_SRFRES_SASA = 0.1
MIN_SRFRES_RASA = 0.05
MIN_INTATM_DASA = 0.1
MIN_SRFATM_SASA = 0.1

DSSP_BIN        = `which dssp`.chomp
DSSP_DIR        = File.join(RAILS_ROOT, "/public/dssp")

BATON_DIR       = File.join(RAILS_ROOT, "/public/baton")
SUBFAM_CUTOFF   = ENV["SUBFAM_CUTOFF"].to_i > 0 ? ENV["SUBFAM_CUTOFF"].to_i : 90

JOY_BIN         = `which joy`.chomp

BLASTCLUST_DIR  = File.join(RAILS_ROOT, "/public/blastclust/")
