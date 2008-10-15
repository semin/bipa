require "matrix"
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
require_dependency "esst"
require_dependency "fugue_hit"
require_dependency "test_alignment"

# Constants for BIPA
RESUME    = (ENV["RESUME"].to_i > 0    ? ENV["RESUME"].to_i    : false)
MAX_FORK  = (ENV["MAX_FORK"].to_i > 0  ? ENV["MAX_FORK"].to_i  : 2)

EPSILON                           = 1.0E-6
MAX_VDW_DISTANCE                  = 3.9
MIN_INTERFACE_RESIDUE_DELTA_ASA   = 1.0
MIN_SURFACE_RESIDUE_ASA           = 0.1
MIN_SURFACE_RESIDUE_RELATIVE_ASA  = 0.07
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

GO_OBO_URI      = "http://www.geneontology.org/ontology/gene_ontology_edit.obo"

HBPLUS_BIN      = "/BiO/Install/hbplus/hbplus"
CLEAN_BIN       = "/BiO/Install/hbplus/clean"
HBADD_BIN       = "/BiO/Install/hbadd/hdadd"
HBPLUS_DIR      = File.join(RAILS_ROOT, "/public/hbplus")
HET_DICT_FILE   = File.join(PDB_MIRROR_DIR, "/data/monomers/het_dictionary.txt")

NACCESS_BIN     = "/BiO/Install/naccess/naccess"
NACCESS_VDW     = "/BiO/Install/naccess/vdw.radii"
NACCESS_STD     = "/BiO/Install/naccess/standard.data"
NACCESS_DIR     = File.join(RAILS_ROOT, "/public/naccess")

DSSP_BIN        = "/BiO/Install/dssp/dsspcmbi"
DSSP_DIR        = File.join(RAILS_ROOT, "/public/dssp")

JOY_BIN         = "/BiO/Install/joy/joy"
JOY_DIR         = File.join(RAILS_ROOT, "/public/joy")

BATON_BIN       = "/BiO/Install/Baton/bin/Baton"
BATON_DIR       = File.join(RAILS_ROOT, "/public/baton")

BLASTCLUST_BIN  = "/usr/bin/blastclust"
BLASTCLUST_DIR  = File.join(RAILS_ROOT, "/public/blastclust/")

FAMILY_DIR      = File.join(RAILS_ROOT, "/public/families")
ALIGNMENT_DIR   = File.join(RAILS_ROOT, "/public/alignments")
ZAP_DIR         = File.join(RAILS_ROOT, "/public/zap")
GO_DIR          = File.join(RAILS_ROOT, "/public/go")
ESST_DIR        = File.join(RAILS_ROOT, "/public/essts")

DNA16_CLASSDEF  = File.join(RAILS_ROOT, "/config/classdef.dna16.dat")
DNA64_CLASSDEF  = File.join(RAILS_ROOT, "/config/classdef.dna64.dat")
RNA16_CLASSDEF  = File.join(RAILS_ROOT, "/config/classdef.rna16.dat")
RNA64_CLASSDEF  = File.join(RAILS_ROOT, "/config/classdef.rna64.dat")
DNASTD_CLASSDEF = File.join(RAILS_ROOT, "/config/classdef.dnastd.dat")
RNASTD_CLASSDEF = File.join(RAILS_ROOT, "/config/classdef.rnastd.dat")
STD_CLASSDEF    = File.join(RAILS_ROOT, "/config/classdef.std.dat")

DNA16_MAT_LOG   = File.join(RAILS_ROOT, "/config/allmat.dna16.log.dat")
DNA64_MAT_LOG   = File.join(RAILS_ROOT, "/config/allmat.dna64.log.dat")
RNA16_MAT_LOG   = File.join(RAILS_ROOT, "/config/allmat.rna16.log.dat")
RNA64_MAT_LOG   = File.join(RAILS_ROOT, "/config/allmat.rna64.log.dat")
STD_MAT_LOG     = File.join(RAILS_ROOT, "/config/allmat.std.log.dat")

ASTRAL40        = "/BiO/Store/SCOP/scopseq/astral-scopdom-seqres-gd-sel-gs-bib-40-1.73.fa"
BALISCORE_BIN   = "/BiO/Install/bali_score/bali_score"
