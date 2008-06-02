class Structure < ActiveRecord::Base

  include Bipa::ComposedOfResidues

  named_scope :untainted, :conditions => { :tainted => false }

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

  def residues
    chains.inject([]) { |s, c| s.concat(c.residues) }
  end
  memoize :residues

  def domains
    aa_chains.inject([]) { |s, a| s.concat(a.domains) }
  end
  memoize :domains

end
