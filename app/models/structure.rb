class Structure < ActiveRecord::Base

#  include Bipa::ComposedOfResidues

  define_index do
    indexes pdb_code, :sortable => true
    indexes classification, :sortable => true
    indexes title, :sortable => true
    indexes exp_method, :sortable => true
    indexes resolution, :sortable => true
    indexes r_value, :sortable => true
    indexes r_free, :sortable => true

    has deposited_at
  end

  has_many  :models,
            :dependent  => :destroy

  has_many  :chains,
            :through    => :models

  has_many  :aa_chains,
            :through    => :models

  has_many  :na_chains,
            :through    => :models

  has_many  :dna_chains,
            :through    => :models

  has_many  :rna_chains,
            :through    => :models

  has_many  :hna_chains,
            :through    => :models

  has_many  :het_chains,
            :through    => :models

  has_many  :residues,
            :through    => :models

  has_many  :aa_residues,
            :through    => :models

  has_many  :na_residues,
            :through    => :models

  has_many  :dna_residues,
            :through    => :models

  has_many  :rna_residues,
            :through    => :models

  has_many  :het_residues,
            :through    => :models

  has_many  :atoms,
            :through    => :models

  has_many  :contacts,
            :through    => :atoms

  has_many  :whbonds,
            :through    => :atoms

  has_many  :hbonds_as_donor,
            :through    => :atoms

  has_many  :hbonds_as_acceptor,
            :through    => :atoms

  has_many  :hbonding_donors,
            :through    => :hbonds_as_acceptor

  has_many  :hbonding_acceptors,
            :through    => :hbonds_as_donor

  named_scope :untainted, :conditions => { :tainted => false }

  named_scope :max_resolution, lambda { |res|
     { :conditions => ["resolution <= ?", res.to_f] }
  }

#  acts_as_ferret  :fields => [ :pdb_code, :classification, :title, :exp_method, :resolution, :r_value, :r_free ],
#                  :remote => true

#  def residues
#    chains.inject([]) { |s, c| s.concat(c.residues) }
#  end
#  memoize :residues

#  def domains
#    aa_chains.inject([]) { |s, a| s.concat(a.domains) }
#  end
#  memoize :domains

end
