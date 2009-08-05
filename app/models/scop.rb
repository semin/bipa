class Scop < ActiveRecord::Base

  include Bipa::Constants

  cattr_reader :version

  @@version = "1.75"

  set_table_name :scop

  acts_as_nested_set

  named_scope :reg_all, :conditions => { :reg_dna => true, :reg_rna => true }

  %w[dna rna].each do |na|
    named_scope :"reg_#{na}", :conditions => { :"reg_#{na}" => true }
    named_scope :"rep_#{na}", :conditions => { :"rep_#{na}" => true }
  end

  define_index do
    indexes :type
    indexes :sunid
    indexes :stype
    indexes :sccs
    indexes :sid
    indexes :description
  end

  def to_param
    self.sunid.to_s
  end

  def self.factory_create!(opts={})
    case opts[:stype]
    when "root" then ScopRoot.create!(opts)
    when "cl"   then ScopClass.create!(opts)
    when "cf"   then ScopFold.create!(opts)
    when "sf"   then ScopSuperFamily.create!(opts)
    when "fa"   then ScopFamily.create!(opts)
    when "dm"   then ScopProtein.create!(opts)
    when "sp"   then ScopSpecies.create!(opts)
    when "px"   then ScopDomain.create!(opts)
    else raise "Unknown SCOP hierarchy: #{opts[:stype]}"
    end
  end

  def hierarchy
    case stype
    when "root" then "Root"
    when "cl"   then "Class"
    when "cf"   then "Fold"
    when "sf"   then "Superfamily"
    when "fa"   then "Family"
    when "dm"   then "Protein"
    when "sp"   then "Species"
    when "px"   then "Domain"
    else "Unknown"
    end
  end

  def scop_domains
    leaves.select { |l| l.reg_dna or l.reg_rna }
  end

  def html_sunid_link
    "http://scop.mrc-lmb.cam.ac.uk/scop/search.cgi?sunid=#{sunid}"
  end

  def html_sccs_link
    "http://scop.mrc-lmb.cam.ac.uk/scop/search.cgi?sccs=#{sccs}"
  end

  def registered?
    reg_dna or reg_rna
  end

  %w[dna rna].each do |na|
    class_eval <<-END
      def #{na}_interfaces
        leaves.map(&:#{na}_interfaces).flatten.compact
      end
    END
  end
end # class Scop


class ScopRoot < Scop
end


class ScopClass < Scop
end


class ScopFold < Scop
end


class ScopSuperFamily < Scop
end


class ScopFamily < Scop

  %w[dna rna].each do |na|
    has_many  :"#{na}_binding_family_alignments",
              :class_name   => "#{na.capitalize}BindingFamilyAlignment",
              :foreign_key  => "scop_id"

    has_many  :"#{na}_binding_subfamilies",
              :class_name   => "#{na.capitalize}BindingSubfamily",
              :foreign_key  => "scop_id"
  end
end


class ScopProtein < Scop
end


class ScopSpecies < Scop
end


class ScopDomain < Scop

  include Bipa::ComposedOfResidues

  %w[dna rna].each do |na|
    belongs_to  :"#{na}_binding_subfamily",
                :class_name   => "#{na.capitalize}BindingSubfamily",
                :foreign_key  => "#{na}_binding_subfamily_id"
  end

  has_many  :dna_interfaces,
            :class_name   => "DomainDnaInterface",
            :foreign_key  => "scop_id"

  has_many  :rna_interfaces,
            :class_name   => "DomainRnaInterface",
            :foreign_key  => "scop_id"

  has_many  :residues,
            :class_name   => "Residue",
            :foreign_key  => "scop_id"

  has_many  :aa_residues,
            :class_name   => "AaResidue",
            :foreign_key  => "scop_id"

  has_many  :chains,
            :through      => :residues,
            :uniq         => true

  has_many  :atoms,
            :through      => :residues

  has_many  :sequences,
            :class_name   => "Sequence",
            :foreign_key  => "scop_id"

  has_many  :fugue_hits,
            :class_name   => "FugueHit",
            :foreign_key  => "scop_id"

  def self.find_all_by_pdb_code(pdb_code)
    find(:all, :conditions => ["sid like ?", "_#{pdb_code.downcase}%"])
  end

  def pdb_code
    sid[1..4].upcase
  end

  def resolution
    res = residues.first.chain.model.structure.resolution
    if res
      res
    else
      999
    end
  end

  def to_sequence
    aa_residues.map(&:one_letter_code).join
  end

  def ranges_on_chains
    # "2hz1 A:2-124, B:1-50" => [A:2-124, B:1-50]
    description.gsub(/^\S{4}\s+/, '').gsub(/\s+/, '').split(',')
  end

  def include?(residue)
    result = false
    if !AminoAcids::Residues::ONE_LETTER_CODE.has_key?(residue.residue_name)
      return result
    end
    ranges_on_chains.each do |range|
      raise "Empty description!" if range =~ /^\s*$/
      case range
      when /^(\S):$/ # F:
        chain_code = $1
        if residue.chain.chain_code == chain_code
          result = true
        end
      when /^-$/ # -
        true
      when /^(-?\d+)-(-?\d+)$/ # 496-581
        res_from  = Integer($1)
        res_to    = Integer($2)
        if ((res_from..res_to).include?(residue[:residue_code]))
          result = true
        end
      when /^(\S):(-?\d+)-(-?\d+)$/ # A:104-157
        chain_code  = $1
        res_from    = Integer($2)
        res_to      = Integer($3)
        if ((residue.chain[:chain_code] == chain_code) &&
            (res_from..res_to).include?(residue[:residue_code]))
          result = true
        end
      else
        raise "#{self.description} should be added to Scop class!"
      end # case
    end # each
    return result
  end

  def scop_class
    parent.parent.parent.parent.parent.parent
  end

  def scop_fold
    parent.parent.parent.parent.parent
  end

  def scop_superfamily
    parent.parent.parent.parent
  end

  def scop_family
    parent.parent.parent
  end

  def scop_protein
    parent.parent
  end

  def scop_species
    parent
  end

  def structure
    residues.first.chain.model.structure
  end

  def big_image
    "/figures/scop/#{sunid}_500.png"
  end

  def big_solo_image
    "/figures/scop/#{sunid}_solo_500.png"
  end

  def small_image
    "/figures/scop/#{sunid}_100.png"
  end

  def small_solo_image
    "/figures/scop/#{sunid}_solo_100.png"
  end
end
