class Structure < ActiveRecord::Base

  acts_as_cached

  after_save :expire_cache

  is_indexed :fields => ["pdb_code", "classification", "title", "exp_method", "resolution"]

  has_many :models,  :dependent => :delete_all
  has_many :chains,  :through => :models
  has_many :domains, :through => :models, :uniq => true
          
  has_many :residues,     :through => :models
  has_many :std_residues, :through => :models
  has_many :aa_residues,  :through => :models
  has_many :na_residues,  :through => :models
  has_many :dna_residues, :through => :models
  has_many :rna_residues, :through => :models
  has_many :het_residues, :through => :models
          
  has_many :atoms,     :through => :residues
  has_many :aa_atoms,  :through => :aa_residues,  :source => :atoms
  has_many :dna_atoms, :through => :dna_residues, :source => :atoms
  has_many :rna_atoms, :through => :rna_residues, :source => :atoms
  has_many :het_atoms, :through => :het_residues, :source => :atoms
          
  has_many :contacts,           :through => :atoms 
  has_many :whbonds,            :through => :atoms
  has_many :hbonds_as_donor,    :through => :atoms
  has_many :hbonds_as_acceptor, :through => :atoms

end
