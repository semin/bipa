# BIPA environment
BIPA_ENV = {
  :MAX_FORK     => ENV["MAX_FORK"].to_i > 0 ? ENV["MAX_FORK"].to_i : 2,
  :NR_CUTOFF    => ENV["NR_CUTOFF"].to_i > 0 ? ENV["NR_CUTOFF"].to_i : 90,
  :ENTRY_TYPE   => "prot-nuc",
  :MAX_DISTANCE => 5.0,

  :INTERFACE_RESIDUE_DELTA_ASA_THRESHOLD  => 1.0,
  :SURFACE_RESIDUE_ASA_THRESHOLD          => 0.1,
  :SURFACE_RESIDUE_RELATIVE_THRESHOLD     => 0.05,
  :INTERFACE_ATOM_DELTA_ASA_THRESHOLD     => 0.1,
  :SURFACE_ATOM_ASA_THRESHOLD             => 0.1,
  :PDB_SOURCE                             => :local,

  :PDB_MIRROR_DIR       => "/BiO/Mirror/PDB",
  :PDB_STRUCTURE_DIR    => "./data/structures/all/pdb",
  :PDB_ENTRY_TYPE_FILE  => "./derived_data/pdb_entry_type.txt",

  :PDB_DIR      => File.join(RAILS_ROOT, "/public/data/pdb"),
  :SCOP_DIR     => File.join(RAILS_ROOT, "/public/data/scop"),
  :SCOP_URI     => "http://scop.mrc-lmb.cam.ac.uk/scop/parse/",
  :PRESCOP_DIR  => File.join(RAILS_ROOT, "/public/data/pre-scop"),
  :PRESCOP_URI  => "http://www.mrc-lmb.cam.ac.uk/agm/pre-scop/parseable/",
  :NCBI_FTP     => "ftp.ncbi.nih.gov",
  :TAXONOMY_DIR => File.join(RAILS_ROOT, "/public/data/taxonomy"),
  :TAXONOMY_FTP => "pub/taxonomy",

  :HBPLUS_DIR   => File.join(RAILS_ROOT, "/public/analysis/hbplus"),
  :HBPLUS_BIN   => File.join(RAILS_ROOT, "/bin/hbplus/hbplus"),
  :CLEAN_BIN    => File.join(RAILS_ROOT, "/bin/hbplus/clean"),

  :NACCESS_DIR  => File.join(RAILS_ROOT, "/public/analysis/naccess"),
  :NACCESS_BIN  => File.join(RAILS_ROOT, "/bin/naccess/naccess"),
  :NACCESS_VDW  => File.join(RAILS_ROOT, "/bin/naccess/vdw.radii"),
  :NACCESS_STD  => File.join(RAILS_ROOT, "/bin/naccess/standard.data"),

  :DSSP_DIR     => File.join(RAILS_ROOT, "/public/analysis/dssp"),
  :DSSP_BIN     => File.join(RAILS_ROOT, "/bin/dssp/dsspcmbi"),

  :DOMAIN_DIR   => File.join(RAILS_ROOT, "/public/analysis/domain"),

  :BATON_SCOP_FAMILY_DIR       => File.join(RAILS_ROOT, "/public/analysis/baton/scop_family"),
  :BLASTCLUST_SCOP_FAMILY_DIR  => File.join(RAILS_ROOT, "/public/analysis/blastclust/scop_family/"),

  :CDHIT_DIR    => File.join(RAILS_ROOT, "/public/analysis/cdhit"),
  :CDHIT_BIN    => File.join(RAILS_ROOT, "/bin/cdhit/cd-hit"),
  :PSICDHIT_BIN => File.join(RAILS_ROOT, "/bin/cdhit/psi-cd-hit.pl"),
  :CDHIT_CUTOFF => 0.8,
  :CDHIT_WORD   => 5,

  :STATS_DIR    => File.join(RAILS_ROOT, "/public/analysis/stats"),
  :STATS_FILE   => "bipa_stats.tsv",
  
  :PDBNUC_DIR             => "/BiO/Store/PDB/CLEAN/PDBNUC",
  :PDBNUC_STRUCTURES_DIR  => "/BiO/Store/PDB/CLEAN/PDBNUC/Structures",
  :PDBNUC_HBPLUS_DIR      => "/BiO/Store/PDB/CLEAN/PDBNUC/HBPLUS",
  :PDBNUC_NACCESS_DIR     => "/BiO/Store/PDB/CLEAN/PDBNUC/NACCESS",
  :PDBNUC_JOY_DIR         => "/BiO/Store/PDB/CLEAN/PDBNUC/JOY",
  :DSSP_MIRROR_DIR        => "/BiO/Mirror/DSSP"
}
