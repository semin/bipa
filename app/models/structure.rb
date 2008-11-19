class Structure < ActiveRecord::Base

  include Bipa::ComposedOfResidues

  define_index do
    indexes pdb_code,       :sortable => true
    indexes classification, :sortable => true
    indexes title,          :sortable => true
    indexes exp_method,     :sortable => true
    indexes resolution,     :sortable => true
    indexes r_value,        :sortable => true
    indexes r_free,         :sortable => true

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

  named_scope :latest, { :order => 'deposited_at DESC' }

  named_scope :untainted, :conditions => {
    :no_zap     => false,
    :no_dssp    => false,
    :no_hbplus  => false,
    :no_naccess => false
  }

  named_scope :max_resolution, lambda { |res|
     { :conditions => ["resolution <= ?", res.to_f] }
  }

  def residues
    chains.inject([]) { |s, c| s.concat(c.residues) }
  end
  memoize :residues

  def domains
    aa_chains.inject([]) { |s, a| s.concat(a.domains) }
  end
  memoize :domains

  def rcsb_image_link
    "http://www.rcsb.org/pdb/images/#{pdb_code.downcase}_bio_r_80.jpg"
  end

end
