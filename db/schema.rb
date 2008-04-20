# This file is auto-generated from the current state of the database. Instead of editing this file,
# please use the migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

include Bipa::Constants

ActiveRecord::Schema.define(:version => 1) do

  # 'scops' table
  create_table "scops", :force => true do |t|
    t.belongs_to  "parent"
    (10..100).step(10) { |i| t.belongs_to "rep#{i}_subfamily" }
    t.integer "lft"
    t.integer "rgt"
    t.string  "type"
    t.integer "sunid"
    t.string  "stype"
    t.string  "sccs"
    t.string  "sid"
    t.string  "description"
    t.boolean "registered", :default => false
  end

  add_index "scops", ["sunid"],                   :name => "index_scops_on_sunid", :unique => true
  add_index "scops", ["parent_id"],               :name => "index_scops_on_parent_id"
  add_index "scops", ["lft"],                     :name => "index_scops_on_lft"
  add_index "scops", ["rgt"],                     :name => "index_scops_on_rgt"
  add_index "scops", ["lft", "rgt"],              :name => "index_scops_on_lft_and_rgt"
  add_index "scops", ["parent_id", "lft"],        :name => "index_scops_on_parent_id_and_lft"
  add_index "scops", ["parent_id", "rgt"],        :name => "index_scops_on_parent_id_and_rgt"
  add_index "scops", ["parent_id", "lft", "rgt"], :name => "index_scops_on_parent_id_and_lft_and_rgt"
  add_index "scops", ["id", "registered"],        :name => "index_scops_on_id_and_registered"


  # 'subfamilies' table
  create_table "subfamilies", :force => true do |t|
    t.belongs_to  "scop"
    t.string      "type"
  end

  add_index "subfamilies", ["scop_id", "type"], :name => "index_sub_families_on_scop_id_and_type"


  # 'alignments' table
  create_table "alignments", :force => true do |t|
    t.belongs_to  "scop"
    t.belongs_to  "subfamily"
    t.string      "type"
  end

  add_index "alignments", ["scop_id", "type"],      :name => "index_alignments_on_scop_id_and_type"
  add_index "alignments", ["subfamily_id", "type"], :name => "index_alignments_on_subfamily_id_and_type"


  # 'sequneces' table
  create_table "sequences", :force => true do |t|
    t.belongs_to  "alignment"
    t.belongs_to  "scop"
    t.belongs_to  "chain"
  end

  add_index "sequences", ["alignment_id"],  :name => "index_sequences_on_alignment_id"
  add_index "sequences", ["scop_id"],       :name => "index_sequences_on_scop_id"
  add_index "sequences", ["chain_id"],      :name => "index_sequences_on_chain_id"


  # 'columns' table
  create_table "columns", :force => true do |t|
    t.belongs_to  "alignment"
    t.integer     "number"
    t.float       "entropy"
    t.float       "relative_entropy"
  end

  add_index "columns", ["alignment_id"],            :name => "index_columns_on_alignment_id"
  add_index "columns", ["alignment_id", "number"],  :name => "index_columns_on_alignment_id_and_number"


  # 'positions' table
  create_table "positions", :force => true do |t|
    t.belongs_to  "sequence"
    t.belongs_to  "column"
    t.belongs_to  "residue"
    t.integer     "number"
    t.string      "residue_name"
  end

  add_index "positions", ["sequence_id"],           :name => "index_positions_on_sequence_id"
  add_index "positions", ["sequence_id", "number"], :name => "index_positions_on_sequence_id_and_number"
  add_index "positions", ["column_id"],             :name => "index_positions_on_column_id"
  add_index "positions", ["residue_id"],            :name => "index_positions_on_residue_id"


  # 'structures' table
  create_table  "structures", :force => true do |t|
    t.string    "pdb_code"
    t.string    "classification"
    t.string    "title"
    t.string    "exp_method"
    t.float     "resolution"
    t.date      "deposited_at"
    t.boolean   "obsolete",   :default => false
    t.boolean   "registered", :default => false
    t.timestamps
  end

  add_index "structures", ["pdb_code"], :name => "index_structures_on_pdb_code", :unique => true


  # 'models' table
  create_table "models", :force => true do |t|
    t.belongs_to  "structure"
    t.integer     "model_code"
  end

  add_index "models", ["model_code"],   :name => "index_models_on_model_code"
  add_index "models", ["structure_id"], :name => "index_models_on_structure_id"


  # 'chains' table
  create_table "chains", :force => true do |t|
    t.belongs_to  "model"
    t.string      "type"
    t.string      "chain_code"
    t.integer     "mol_code"
    t.string      "molecule"
    t.boolean     "registered"
  end

  add_index "chains", ["chain_code"],             :name => "index_chains_on_chain_code"
  add_index "chains", ["registered"],             :name => "index_chains_on_registered"
  add_index "chains", ["model_id"],               :name => "index_chains_on_model_id"
  add_index "chains", ["model_id", "chain_code"], :name => "index_chains_on_model_id_and_chain_code"


  # 'resdiues' table
  create_table "residues", :force => true do |t|
    t.belongs_to  "chain"
    t.belongs_to  "scop"
    t.belongs_to  "chain_interface"
    t.belongs_to  "domain_interface"
    t.belongs_to  "res_map"
    t.belongs_to  "residue_map"
    t.string      "type"
    t.string      "icode"
    t.integer     "residue_code"
    t.string      "residue_name"
    t.string      "secondary_structure"
    t.string      "hydrophobicity"
  end

  add_index "residues", ["chain_id"],                           :name => "index_residues_on_chain_id"
  add_index "residues", ["scop_id"],                            :name => "index_residues_on_scop_id"
  add_index "residues", ["domain_interface_id"],                :name => "index_residues_on_domain_interface_id"
  add_index "residues", ["chain_interface_id"],                 :name => "index_residues_on_chain_interface_id"
  add_index "residues", ["res_map_id"],                         :name => "index_residues_on_res_map_id"
  add_index "residues", ["residue_map_id"],                     :name => "index_residues_on_residue_map_id"
  add_index "residues", ["residue_name"],                       :name => "index_residues_on_residue_name"
  add_index "residues", ["type"],                               :name => "index_residues_on_type"
  add_index "residues", ["icode", "residue_code"],              :name => "index_residues_on_icode_and_residue_code"
  add_index "residues", ["chain_id", "icode", "residue_code"],  :name => "index_residues_on_chain_id_and_icode_and_residue_code"
  add_index "residues", ["chain_id", "residue_name"],           :name => "index_residues_on_chain_id_and_residue_name"
  add_index "residues", ["chain_id", "scop_id"],                :name => "index_residues_on_chain_id_and_scop_id"
  add_index "residues", ["chain_id", "type"],                   :name => "index_residues_on_chain_id_and_type"
  add_index "residues", ["id", "domain_interface_id"],          :name => "index_residues_on_id_and_domain_interface_id"
  add_index "residues", ["id", "chain_interface_id"],           :name => "index_residues_on_id_and_chain_interface_id"


  # 'atoms' table
  create_table "atoms", :force => true do |t|
    t.belongs_to  "residue"
    t.string      "position_type"
    t.integer     "atom_code"
    t.string      "atom_name"
    t.string      "altloc"
    t.float       "x"
    t.float       "y"
    t.float       "z"
    t.float       "occupancy"
    t.float       "tempfactor"
    t.string      "element"
    t.string      "charge"
    t.float       "bound_asa"
    t.float       "unbound_asa"
    t.float       "delta_asa"
    t.float       "radius"
    t.float       "formal_charge"
    t.float       "partial_charge"
    t.float       "potential"
  end

  add_index "atoms", ["residue_id"],              :name => "index_atoms_on_residue_id"
  add_index "atoms", ["residue_id", "atom_code"], :name => "index_atoms_on_residue_id_and_atom_code"
  add_index "atoms", ["residue_id", "atom_name"], :name => "index_atoms_on_residue_id_and_atom_name"
  add_index "atoms", ["atom_code"],               :name => "index_atoms_on_atom_code"
  add_index "atoms", ["atom_name"],               :name => "index_atoms_on_atom_name"


  # 'contacts' table
  create_table "contacts", :force => true do |t|
    t.belongs_to  "atom"
    t.belongs_to  "contacting_atom"
    t.float       "distance"
  end

  add_index "contacts", ["atom_id"],                        :name => "index_contacts_on_atom_id"
  add_index "contacts", ["contacting_atom_id"],             :name => "index_contacts_on_contacting_atom_id"
  add_index "contacts", ["atom_id", "contacting_atom_id"],  :name => "index_contacts_on_atom_id_and_contacting_atom_id"
  add_index "contacts", ["contacting_atom_id", "atom_id"],  :name => "index_contacts_on_contacting_atom_id_and_atom_id"


  # 'hbonds' table
  create_table "hbonds", :force => true do |t|
    t.belongs_to  "donor"
    t.belongs_to  "acceptor"
    t.float       "da_distance"
    t.string      "category"
    t.integer     "gap"
    t.float       "ca_distance"
    t.float       "dha_angle"
    t.float       "ha_distance"
    t.float       "haaa_angle"
    t.float       "daaa_angle"
  end

  add_index "hbonds", ["donor_id", "acceptor_id"],  :name => "index_hbonds_on_donor_id_and_acceptor_id"
  add_index "hbonds", ["acceptor_id", "donor_id"],  :name => "index_hbonds_on_acceptor_id_and_donor_id"
  add_index "hbonds", ["donor_id"],                 :name => "index_hbonds_on_donor_id"
  add_index "hbonds", ["acceptor_id"],              :name => "index_hbonds_on_acceptor_id"


  # 'whbonds' table
  create_table "whbonds", :force => true do |t|
    t.belongs_to "atom"
    t.belongs_to "whbonding_atom"
    t.belongs_to "water_atom"
  end

  add_index "whbonds", ["atom_id", "whbonding_atom_id"],  :name => "index_whbonds_on_atom_id_and_whbonding_atom_id"
  add_index "whbonds", ["whbonding_atom_id", "atom_id"],  :name => "index_whbonds_on_whbonding_atom_id_and_atom_id"
  add_index "whbonds", ["atom_id"],                       :name => "index_whbonds_on_atom_id"
  add_index "whbonds", ["whbonding_atom_id"],             :name => "index_whbonds_on_whbonding_atom_id"


  # 'interface' table
  create_table :interfaces, :force => true do |t|
    t.belongs_to  "scop"
    t.belongs_to  "chain"
    t.string      "type"
    t.float       "asa"
    t.float       "polarity"

    AminoAcids::Residues::STANDARD.each do |aa|
      t.float "singlet_propensity_of_#{aa.downcase}"
    end

    Dssp::SSES.each do |sse|
      t.float "sse_propensity_of_#{sse.downcase}"
    end

    %w(hbond whbond contact).each do |intact|

      %w(sugar phosphate).each do |moiety|
        t.integer "frequency_of_#{intact}_between_amino_acids_and_#{moiety}"
      end

      AminoAcids::Residues::STANDARD.each do |aa|
        t.integer "frequency_of_#{intact}_between_#{aa.downcase}_and_nucleic_acids"

        %w(sugar phosphate).each do |moiety|
          t.integer "frequency_of_#{intact}_between_#{aa.downcase}_and_#{moiety}"
        end
      end

      %w(dna rna).each do |na|

        na_residues = "NucleicAcids::#{na.camelize}::Residues::STANDARD".constantize

        na_residues.each do |nar|

          t.integer "frequency_of_#{intact}_between_amino_acids_and_#{nar.downcase}"

          AminoAcids::Residues::STANDARD.each do |aa|
            t.integer "frequency_of_#{intact}_between_#{aa.downcase}_and_#{nar.downcase}"
          end
        end
      end
    end
  end

  add_index "interfaces", ["scop_id"],          :name => "index_interfaces_on_scop_id"
  add_index "interfaces", ["chain_id"],         :name => "index_interfaces_on_chain_id"
  add_index "interfaces", ["id", "scop_id"],    :name => "index_interfaces_on_id_and_scop_id"
  add_index "interfaces", ["id", "chain_id"],   :name => "index_interfaces_on_id_and_chain_id"
  add_index "interfaces", ["scop_id", "type"],  :name => "index_interfaces_on_scop_id_and_type"
  add_index "interfaces", ["chain_id", "type"], :name => "index_interfaces_on_chain_id_and_type"
end
