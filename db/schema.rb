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
include BIPA::Constants

ActiveRecord::Schema.define(:version => 1) do

  # 'scops' table
  create_table "scops", :force => true do |t|
    t.belongs_to  "parent"
    (10..100).step(10) { |i| t.belongs_to  "sub_family#{i}" }
    t.integer     "lft"
    t.integer     "rgt"
    t.string      "type"
    t.integer     "sunid",      :null => false
    t.string      "stype",      :null => false
    t.string      "sccs"
    t.string      "sid"
    t.string      "pdb_code"
    t.string      "description"
    t.boolean     "registered", :default => false
  end

  add_index "scops", ["sunid"],                   :name => "index_scops_on_sunid", :unique => true
  add_index "scops", ["pdb_code"],                :name => "index_scops_on_pdb_code"
  add_index "scops", ["parent_id"],               :name => "index_scops_on_parent_id"
  add_index "scops", ["lft"],                     :name => "index_scops_on_lft"
  add_index "scops", ["rgt"],                     :name => "index_scops_on_rgt"
  add_index "scops", ["lft", "rgt"],              :name => "index_scops_on_lft_and_rgt"
  add_index "scops", ["parent_id", "lft"],        :name => "index_scops_on_parent_id_and_lft"
  add_index "scops", ["parent_id", "rgt"],        :name => "index_scops_on_parent_id_and_rgt"
  add_index "scops", ["parent_id", "lft", "rgt"], :name => "index_scops_on_parent_id_and_lft_and_rgt"
  add_index "scops", ["id", "registered"],        :name => "index_scops_on_id_and_registered"


  # 'sub_families' table
  create_table "sub_families", :force => true do |t|
    t.belongs_to  "scop_family"
    t.string      "type"
  end

  add_index "sub_families", ["scop_family_id", "type"], :name => "index_sub_families_on_scop_family_id_and_type"

  #
  create_table "alignments", :force => true do |t|
    t.belongs_to "sub_family"
  end

  # 'structures' table
  create_table  "structures", :force => true do |t|
    t.string    "pdb_code",       :null => false
    t.string    "classification", :null => false
    t.string    "title"
    t.string    "exp_method",     :null => false
    t.float     "resolution"
    t.date      "deposited_at",   :null => false
    t.boolean   "obsolete",       :default => false
    t.timestamps
  end

  add_index "structures", ["pdb_code"], :name => "index_structures_on_pdb_code", :unique => true


  # 'models' table
  create_table "models", :force => true do |t|
    t.belongs_to  "structure",  :null => false
    t.integer     "model_code", :null => false
  end

  add_index "models", ["model_code"],   :name => "index_models_on_model_code"
  add_index "models", ["structure_id"], :name => "index_models_on_structure_id"


  # 'chains' table
  create_table "chains", :force => true do |t|
    t.belongs_to  "model",      :null => false
    t.string      "type"
    t.string      "chain_code", :null => false
    t.integer     "mol_code"
    t.string      "molecule"
  end

  add_index "chains", ["chain_code"],             :name => "index_chains_on_chain_code"
  add_index "chains", ["model_id"],               :name => "index_chains_on_model_id"
  add_index "chains", ["model_id", "chain_code"], :name => "index_chains_on_model_id_and_chain_code"


  # 'resdiues' table
  create_table "residues", :force => true do |t|
    t.belongs_to  "chain",              :null => false
    t.belongs_to  "scop"
    t.belongs_to  "chain_interface"
    t.belongs_to  "domain_interface"
    t.belongs_to  "res_map"
    t.belongs_to  "residue_map"
    t.string      "type",               :null => false
    t.string      "icode"
    t.integer     "residue_code",       :null => false
    t.string      "residue_name",       :null => false
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
    t.belongs_to  "residue",          :null => false
    t.string      "position_type"
    t.integer     "atom_code",           :null => false
    t.string      "atom_name",           :null => false
    t.string      "altloc"
    t.float       "x",                   :null => false
    t.float       "y",                   :null => false
    t.float       "z",                   :null => false
    t.float       "occupancy",           :null => false
    t.float       "tempfactor",          :null => false
    t.string      "element"
    t.string      "charge"
    t.float       "bound_asa"
    t.float       "unbound_asa"
    t.float       "delta_asa"
  end

  add_index "atoms", ["residue_id"],                :name => "index_atoms_on_residue_id"
  add_index "atoms", ["residue_id", "atom_code"],   :name => "index_atoms_on_residue_id_and_atom_code"
  add_index "atoms", ["residue_id", "atom_name"],   :name => "index_atoms_on_residue_id_and_atom_name"
  add_index "atoms", ["atom_code"],                 :name => "index_atoms_on_atom_code"
  add_index "atoms", ["atom_name"],                 :name => "index_atoms_on_atom_name"

  # 'contacts' table
  create_table "contacts", :force => true do |t|
    t.belongs_to  "atom",            :null => false
    t.belongs_to  "contacting_atom", :null => false
    t.float       "distance",           :null => false
  end

  add_index "contacts", ["atom_id"],                        :name => "index_contacts_on_atom_id"
  add_index "contacts", ["contacting_atom_id"],             :name => "index_contacts_on_contacting_atom_id"
  add_index "contacts", ["atom_id", "contacting_atom_id"],  :name => "index_contacts_on_atom_id_and_contacting_atom_id"
  add_index "contacts", ["contacting_atom_id", "atom_id"],  :name => "index_contacts_on_contacting_atom_id_and_atom_id"

  # 'hbonds' table
  create_table "hbonds", :force => true do |t|
    t.belongs_to  "hbonding_donor",    :null => false
    t.belongs_to  "hbonding_acceptor", :null => false
    t.float       "da_distance",       :null => false
    t.string      "category",          :null => false
    t.integer     "gap"
    t.float       "ca_distance"
    t.float       "dha_angle"
    t.float       "ha_distance"
    t.float       "haaa_angle"
    t.float       "daaa_angle"
  end

  add_index "hbonds", ["hbonding_donor_id", "hbonding_acceptor_id"],  :name => "index_hbonds_on_hbonding_donor_id_and_hbonding_acceptor_id", :unique => true
  add_index "hbonds", ["hbonding_acceptor_id", "hbonding_donor_id"],  :name => "index_hbonds_on_hbonding_acceptor_id_and_hbonding_donor_id", :unique => true
  add_index "hbonds", ["hbonding_donor_id"],                          :name => "index_hbonds_on_hbonding_donor_id"
  add_index "hbonds", ["hbonding_acceptor_id"],                       :name => "index_hbonds_on_hbonding_acceptor_id"

  # 'whbonds' table
  create_table "whbonds", :force => true do |t|
    t.belongs_to "atom",           :null => false
    t.belongs_to "whbonding_atom", :null => false
    t.belongs_to "water_atom",     :null => false
  end

  add_index "whbonds", ["atom_id", "whbonding_atom_id"],  :name => "index_whbonds_on_atom_id_and_whbonding_atom_id", :unique => true
  add_index "whbonds", ["whbonding_atom_id", "atom_id"],  :name => "index_whbonds_on_whbonding_atom_id_and_atom_id", :unique => true
  add_index "whbonds", ["atom_id"],                       :name => "index_whbonds_on_atom_id"
  add_index "whbonds", ["whbonding_atom_id"],             :name => "index_whbonds_on_whbonding_atom_id"

  # 'interface' table
  create_table :interfaces, :force => true do |t|
    t.belongs_to  "scop"
    t.belongs_to  "chain"
    t.string      "type"
    t.float       "asa"
    t.float       "polarity"

    AminoAcids::Residues::STANDARD.map(&:downcase).each { |a| t.float "singlet_propensity_of_#{a}" }
    DSSP::SSES.map(&:downcase).each { |s| t.float "sse_propensity_of_#{s}" }

    %w(hbond whbond contact).each do |int|
      %w(dna rna).each do |na|
        na_residues = "NucleicAcids::#{na.upcase}::Residues::STANDARD".constantize.map(&:downcase)
        na_residues.each { |r| t.integer "frequency_of_#{int}_between_amino_acids_and_#{r}" }
        %w(sugar phosphate).each { |m| t.integer "frequency_of_#{int}_between_amino_acids_and_#{m}" }

        AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa|
          %w(sugar phosphate).each { |m| t.integer "frequency_of_#{int}_between_#{aa}_and_#{m}" }
          na_residues.each { |r| t.integer "frequency_of_#{int}_between_#{aa}_and_#{r}" }
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
