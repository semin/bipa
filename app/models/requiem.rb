class Requiem < ActiveRecord::Base

  self.abstract_class = true
  establish_connection "REQUIEM"

end


class Omim < Requiem

  set_table_name :OMIM

end


class Variation2PDB < Requiem

  set_table_name :Variation2PDB

  belongs_to  :variation,
              :class_name => "Variation",
              :foreign_key => :variation_id

end


class Variation2Uniprot < Requiem

  set_table_name :Variation2UniProt

  belongs_to  :variation,
              :class_name => "Variation",
              :foreign_key => :variation_id

end


class Variation < Requiem

  set_table_name :Variations

  has_many  :variation2_pdbs,
            :class_name => "Variation2PDB",
            :foreign_key => :variation_id

  has_many  :variation2_uniprots,
            :class_name => "Variation2Uniprot",
            :foreign_key => :variation_id

  named_scope :sysnonymous,     :conditions => ["consequence_type LIKE ?", "SYNONYMOUS%"]
  named_scope :non_sysnonymous, :conditions => ["consequence_type LIKE ?", "NON_SYNONYMOUS%"]

  # Tags for synonymousity of variation have to use
  # 'consequence_type_before_type_cast' because its original
  # type it MySQL SET.
  def synonymous?
    consequence_type_before_type_cast.andand.match(/^SYNONYMOUS/)
  end

  def non_synonymous?
    consequence_type_before_type_cast.andand.match(/^NON_SYNONYMOUS/)
  end

  def omims
    variation2_uniprots.map { |vu|
      Omim.find_by_uniprot_and_uniprot_res_num(vu.uniprot, vu.uniprot_res_num)
    }.compact
  end

  def dbsnp_url
    code = variation_name.match(/^rs(\d+)/).andand[0]
    if code
      "http://www.ncbi.nlm.nih.gov/SNP/snp_ref.cgi?rs=#{code}"
    else
      nil
    end
  end
end
