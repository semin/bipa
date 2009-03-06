class Structure < ActiveRecord::Base

  include Bipa::ComposedOfResidues

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

  define_index do
    indexes :pdb_code
    indexes :classification
    indexes :title
    indexes :exp_method
    indexes :resolution

    has :deposited_at
  end

  def residues
    chains.inject([]) { |s, c| s.concat(c.residues) }
  end
  memoize :residues

  def domains
    aa_chains.inject([]) { |s, a| s.concat(a.domains) }
  end
  memoize :domains

  def rcsb_image_link_80
    "http://www.rcsb.org/pdb/images/#{pdb_code.downcase}_bio_r_80.jpg"
  end

  def rcsb_image_link_250
    "http://www.rcsb.org/pdb/images/#{pdb_code.downcase}_asym_r_250.jpg"
  end

  def rcsb_image_link_500
    "http://www.rcsb.org/pdb/images/#{pdb_code.downcase}_asym_r_500.jpg"
  end

  def small_image
    "/images/pdb/#{pdb_code.downcase}_100.png"
  end

  def big_image
    "/images/pdb/#{pdb_code.downcase}_500.png"
  end

  def authors
    @authors = AuditAuthor.find_all_by_Structure_ID(pdb_code).map(&:name).to_sentence
    @authors.nil? ? "N/A" : @authors
  end

  def citation
    citation = Citation.find_by_Structure_ID(pdb_code)
    "#{authors} (#{citation.year}), #{citation.title}. #{citation.journal_abbrev} #{citation.journal_volume}:#{citation.page_first}-#{citation.page_last}"
  end

  def released_at
    dbstatus = PdbxDatabaseStatus.find([pdb_code, pdb_code])
    dbstatus.date_of_PDB_release
  end

  def source
    "N/A"
  end

  def abstract
    citation   = Citation.find_by_Structure_ID(pdb_code)
    pubmed     = Bio::PubMed.efetch(citation.pdbx_database_id_PubMed)
    medline    = Bio::MEDLINE.new(pubmed)
    medline.abstract.empty? ? "N/A" : medline.abstract
  end

  def pubmed_link
    citation = Citation.find_by_Structure_ID(pdb_code)
    "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Retrieve&db=PubMed&dopt=Abstract&list_uids=#{citation.pdbx_database_id_PubMed}"
  end

  def doi_link
    citation = Citation.find_by_Structure_ID(pdb_code)
    "http://dx.doi.org/#{citation.pdbx_database_id_DOI}"
  end

  def resolution_for_html
    resolution ? "%.2f &Aring;" % resolution : "N/A"
  end

  def rcsb_html_link
    "http://www.rcsb.org/pdb/explore.do?structureId=#{pdb_code}"
  end

end
