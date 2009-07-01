class Chain < ActiveRecord::Base

  include Bipa::ComposedOfResidues

  belongs_to  :model

  has_many  :residues,
            :dependent    => :destroy

  has_many  :std_residues

  has_many  :aa_residues

  has_many  :na_residues

  has_many  :dna_residues

  has_many  :rna_residues

  has_many  :het_residues

  has_many  :atoms,
            :through      => :residues

  has_many  :std_atoms,
            :through      => :std_residues

  has_many  :aa_atoms,
            :through      => :aa_residues,
            :source       => :atoms

  has_many  :na_atoms,
            :through      => :na_residues,
            :source       => :atoms

  has_many  :dna_atoms,
            :through      => :dna_residues,
            :source       => :atoms

  has_many  :rna_atoms,
            :through      => :rna_residues,
            :source       => :atoms

  has_many  :het_atoms,
            :through      => :het_residues,
            :source       => :atoms

  has_many  :sequences

  has_many  :goa_pdbs

  has_many  :go_terms,
            :through      => :goa_pdbs

  validates_uniqueness_of :chain_code,
                          :scope          => :model_id,
                          :allow_nil      => true,
                          :case_sensitive => true

  def fasta_header
    "#{model.structure.pdb_code}:#{chain_code}"
  end

  def go_terms_for_html(namespace = :molecular_function)
    gos = go_terms.send(namespace)
    if gos.size > 0
      gos.map { |g| g.name }.uniq.join("<br />")
    else
      "N/A"
    end
  end
end


class AaChain < Chain

  belongs_to  :model

  has_many  :dna_interfaces,
            :class_name   => "ChainDnaInterface",
            :foreign_key  => "chain_id"

  has_many  :rna_interfaces,
            :class_name   => "ChainRnaInterface",
            :foreign_key  => "chain_id"

  has_many  :domains,
            :through      => :residues,
            :uniq         => true

  def ruler_with_margin(margin = 0)
    "&nbsp;" * margin + (1..std_residues.size).map { |i|
      case
      when i <= 10
        i % 10 == 0 ? i : "&nbsp;"
      when i > 10 && i < 100
        if i % 10 == 0 then i
        elsif i % 10 == 1 then ""
        else; "&nbsp;"; end
      when i >= 100 && i < 1000
        if i % 10 == 0 then i
        elsif i % 10 == 1 || i % 10 == 2 then ""
        else; "&nbsp;"; end
      end
    }.join
  end

  def res_seq
    std_residues.map(&:one_letter_code).join
  end

  def sse_seq
    std_residues.map(&:sse).join
  end

  def asa_seq
    std_residues.map { |r| r.on_surface? ? "A" : "a" }.join
  end

  def hbd_dna_seq
    std_residues.map { |r| r.hbonding_dna? ? "T" : "." }.join
  end

  def whb_dna_seq
    std_residues.map { |r| r.whbonding_dna? ? "T" : "." }.join
  end

  def vdw_dna_seq
    std_residues.map { |r| r.vdw_contacting_dna? ? "T" : "." }.join
  end

  def hbd_rna_seq
    std_residues.map { |r| r.hbonding_rna? ? "T" : "." }.join
  end

  def whb_rna_seq
    std_residues.map { |r| r.whbonding_rna? ? "T" : "." }.join
  end

  def vdw_rna_seq
    std_residues.map { |r| r.vdw_contacting_rna? ? "T" : "." }.join
  end

  def formatted_sequence
    std_residues.map { |r| r.formatted_residue_name rescue "X" }.join
  end
end


class NaChain < Chain

  belongs_to  :model

end


class DnaChain < NaChain

  belongs_to  :model

end


class RnaChain < NaChain

  belongs_to  :model

end


class HnaChain < NaChain

  belongs_to  :model

end


class PseudoChain < Chain

  belongs_to  :model

end
