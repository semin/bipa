class Residue < ActiveRecord::Base

  include Bipa::Constants
  include Bipa::ComposedOfAtoms

  belongs_to  :chain,
              :class_name   => "Chain",
              :foreign_key  => "chain_id"

  belongs_to  :domain,
              :class_name   => "ScopDomain",
              :foreign_key  => "scop_id"

  belongs_to  :domain_interface,
              :class_name   => "DomainInterface",
              :foreign_key  => "domain_interface_id"

  belongs_to  :res_map,
              :class_name   => "ResMap",
              :foreign_key  => "res_map_id"

  belongs_to  :residue_map,
              :class_name   => "ResidueMap",
              :foreign_key  => "residue_map_id"

  has_one :dssp,
          :class_name   => "Dssp",
          :foreign_key  => "residue_id"

  delegate :sse, :to => :dssp

  has_many  :atoms,
            :class_name   => "Atom",
            :foreign_key  => "residue_id",
            :dependent    => :destroy

  has_many  :positions

  named_scope :on_interface, {:conditions => ['domain_interface_id IS NOT NULL'] }

  ZeroArray20 = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]

  def array20
    case residue_name
    when /ALA/i then [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    when /CYS/i then [0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    when /ASP/i then [0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    when /GLU/i then [0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    when /PHE/i then [0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    when /GLY/i then [0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    when /HIS/i then [0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0]
    when /ILE/i then [0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0]
    when /LYS/i then [0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0]
    when /LEU/i then [0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0]
    when /MET/i then [0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0]
    when /ASN/i then [0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0]
    when /PRO/i then [0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0]
    when /GLN/i then [0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0]
    when /ARG/i then [0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0]
    when /SER/i then [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0]
    when /THR/i then [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0]
    when /VAL/i then [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0]
    when /TRP/i then [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0]
    when /TYR/i then [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1]
    end
  end

  def positive_phi?
    (dssp.phi > 0 and dssp.phi != 360.0) rescue false
  end

  def helix?
    (sse == "H" or sse == "I" or sse == "G") rescue false
  end

  def beta_sheet?
    (sse == "E" or sse == "B") rescue false
  end

  def coil?
    (sse == "C") rescue false
  end

  def on_surface?
    relative_unbound_asa >= MIN_SURFACE_RESIDUE_RELATIVE_ASA
  end

  def buried?
    !on_surface?
  end

  def on_interface?
    delta_asa >= MIN_INTERFACE_RESIDUE_DELTA_ASA
  end

  def disulfide_bond?
    ss ? true : false
  end

  def one_letter_code
    AminoAcids::Residues::ONE_LETTER_CODE[residue_name] or "X"
  end

  def formatted_residue_name
    css_class = []

    case
    when positive_phi?  then css_class << "positive_phi"
    when helix?         then css_class << "helix"
    when beta_sheet?    then css_class << "beta_sheet"
    end

    css_class << (on_surface? ? "on_surface" : "buried")

    if ((hbonding_dna? || whbonding_dna? || vdw_contacting_dna?) &&
        (hbonding_rna? || whbonding_rna? || vdw_contacting_rna?))
      css_class << "binding_both"
    else
      css_class << "hbonding_dna"       if hbonding_dna?
      css_class << "whbonding_dna"      if whbonding_dna?
      css_class << "vdw_contacting_dna" if vdw_contacting_dna?

      css_class << "hbonding_rna"       if hbonding_rna?
      css_class << "whbonding_rna"      if whbonding_rna?
      css_class << "vdw_contacting_rna" if vdw_contacting_rna?
    end

    res_code = if disulfide_bond?
                 if on_surface?
                   "&Ccedil;"
                 else
                   "&ccedil;"
                 end
               else
                 one_letter_code
               end
    "<span class='#{css_class.join(' ')}'>#{res_code}</span>"
  end
  # this is for regular 'residue' types except 'AaResidue',
  # which has its own definition of surface residue
  def on_surface?
    surface_atoms.size > 0
  end

  # this is for regular 'residue' types except 'AaResidue',
  # which has its own definition of 'interface residue'
  def on_interface?
    interface_atoms.size > 0
  end

  def buried?
    !on_surface?
  end

  def aa?
    is_a?(AaResidue)
  end

  def na?
    is_a?(NaResidue)
  end

  def dna?
    is_a?(DnaResidue)
  end

  def rna?
    is_a?(RnaResidue)
  end

  def het?
    is_a?(HetResidue)
  end

  def water?
    residue_name == "HOH"
  end

  def justified_residue_name
    residue_name.rjust(3)
  end

  def justified_residue_code
    residue_code.to_s.rjust(4, '0')
  end

  %w(unbound bound delta).each do |state|
    class_eval <<-EVAL
      def calculate_#{state}_asa
        atoms.inject(0) { |s, a| !a.#{state}_asa.nil? ? s + a.#{state}_asa : s } rescue 0
      end

      def relative_#{state}_asa
        if AminoAcids::Residues::STANDARD.include?(residue_name)
            self[:#{state}_asa] / AminoAcids::Residues::STANDARD_ASA[residue_name]
        else
          raise "Unknown residue type: \#{id}, \#{residue_name}"
        end
      end
    EVAL
  end

  def variations
    ins_code = icode.nil? ? '' : icode
    var2pdbs = Variation2PDB.find(:all,
                                  :conditions => {:pdb          => chain.model.structure.pdb_code,
                                                  :pdb_chain_id => chain.chain_code,
                                                  :pdb_res_num  => residue_code,
                                                  :pdb_ins_code => ins_code })
    var2pdbs.map { |vp| vp.variation }
  end

  def nssnps
    variations.select { |v| v.non_synonymous? }
  end

  def ssnps
    variations.select { |v| v.synonymous? }
  end

  def disease_nssnps
    nssnps.select { |v| v.omims.size > 0 }
  end

  def uniprot_features
    # temporary remedy for during Gloria.ResMap downtime
    #return []

    resmap = ResMap.find(:first, :conditions => {
      :pdb => chain.model.structure.pdb_code.downcase,
      :pdb_chain_id => chain.chain_code,
      :res_3code => residue_name,
      :pdb_res_num => residue_code
    })

    if resmap
      Feature.find(:all,
                   :conditions => ['acc = ? and start = ? and end = ?',
                                   resmap.uniprot,
                                   resmap.uniprot_res_num,
                                   resmap.uniprot_res_num])
    else
      []
    end
  end
end # class Residue


class StdResidue < Residue

  has_many  :atoms,
            :class_name   => "StdAtom",
            :foreign_key  => "residue_id"
end


class HetResidue < Residue

  has_many  :atoms,
            :class_name   => "HetAtom",
            :foreign_key  => "residue_id"
end


class AaResidue < StdResidue
end


class NaResidue < StdResidue
end


class DnaResidue < NaResidue
end


class RnaResidue < NaResidue
end
