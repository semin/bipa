# BIPA environment
BIPA_ENV = {
  :MAX_FORK       => ENV["MAX_FORK"].to_i > 0 ? ENV["MAX_FORK"].to_i : 2,

  :PDB_SRC        => :remote,
  :PDB_MIRROR_DIR => "/BiO/Mirror/PDB",
  :PDB_ZIPPED_DIR => "./data/structures/all/pdb",
  :PDB_ENTRY_FILE => "./derived_data/pdb_entry_type.txt",
  :PDB_ENTRY_TYPE => "prot-nuc",
  :PDB_DIR        => File.join(RAILS_ROOT, "/public/pdb"),
  :PDB_FTP        => "ftp.ebi.ac.uk",
  
  :SCOP_DIR       => File.join(RAILS_ROOT, "/public/scop"),
  :SCOP_URI       => "http://scop.mrc-lmb.cam.ac.uk/scop/parse/",
  
  :PRESCOP_DIR    => File.join(RAILS_ROOT, "/public/data/pre-scop"),
  :PRESCOP_URI    => "http://www.mrc-lmb.cam.ac.uk/agm/pre-scop/parseable/",
  
  :NCBI_FTP       => "ftp.ncbi.nih.gov",
  :TAXONOMY_DIR   => File.join(RAILS_ROOT, "/public/taxonomy"),
  :TAXONOMY_FTP   => "pub/taxonomy",

  :HBPLUS_DIR   => File.join(RAILS_ROOT, "/public/hbplus"),
  :HBPLUS_BIN   => `which hbplus`,
  :CLEAN_BIN    => `which clean`,

  :NACCESS_DIR  => File.join(RAILS_ROOT, "/public/naccess"),
  :NACCESS_BIN  => `which naccess`,
  :NACCESS_VDW  => File.join(RAILS_ROOT, "/config/vdw.radii"),
  :NACCESS_STD  => File.join(RAILS_ROOT, "/config/standard.data"),
  
  :MAX_DISTANCE     => 5.0,
  :MIN_INTRES_DASA  => 1.0,
  :MIN_SRFRES_SASA  => 0.1,
  :MIN_SRFRES_RASA  => 0.05,
  :MIN_INTATM_DASA  => 0.1,
  :MIN_SRFATM_SASA  => 0.1,

  :DSSP_DIR     => File.join(RAILS_ROOT, "/public/dssp"),
  :DSSP_BIN     => `which dssp`,

  :BATON_DIR      => File.join(RAILS_ROOT, "/public/baton"),
  :SUBFAM_CUTOFF  => ENV["SUBFAM_CUTOFF"].to_i > 0 ? ENV["SUBFAM_CUTOFF"].to_i : 90,
  
  :BLASTCLUST_DIR => File.join(RAILS_ROOT, "/public/blastclust/"),
}
