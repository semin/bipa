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

  # 'scop' table
  create_table :scop, :force => true do |t|
    t.belongs_to  :parent
    t.integer     :lft
    t.integer     :rgt
    t.string      :type
    t.integer     :sunid
    t.string      :stype
    t.string      :sccs
    t.string      :sid
    t.string      :description
    t.float       :resolution
    %w[dna rna].each { |na|
      (10..100).step(10) { |pid| t.belongs_to  :"nr#{pid}_#{na}_binding_subfamily" }
      t.boolean     :"rp_#{na}",    :default => false
      t.boolean     :"rpall_#{na}", :default => false
    }
    t.boolean     :rpall, :default => false
  end

  add_index :scop, :sunid
  add_index :scop, :parent_id
  add_index :scop, :lft
  add_index :scop, :rgt
  add_index :scop, [:id, :type]


  # 'structures' table
  create_table :structures, :force => true do |t|
    t.string    :pdb_code
    t.string    :classification
    t.string    :title
    t.string    :exp_method
    t.float     :resolution
    t.float     :r_value
    t.float     :r_free
    t.string    :space_group
    t.date      :deposited_at
    t.boolean   :obsolete,    :default => false
    t.boolean   :no_zap,      :default => false
    t.boolean   :no_dssp,     :default => false
    t.boolean   :no_hbplus,   :default => false
    t.boolean   :no_naccess,  :default => false
    t.timestamps
  end

  add_index :structures, :pdb_code,     :unique => true
  add_index :structures, :resolution
  add_index :structures, :r_value
  add_index :structures, :r_free
  add_index :structures, :deposited_at
  add_index :structures, :no_zap
  add_index :structures, :no_dssp
  add_index :structures, :no_hbplus
  add_index :structures, :no_naccess


  # 'models' table
  create_table :models, :force => true do |t|
    t.belongs_to  :structure
    t.integer     :model_code
  end

  add_index :models, :structure_id
  add_index :models, :model_code


  # 'chains' table
  create_table :chains, :force => true do |t|
    t.belongs_to  :model
    t.string      :type
    t.string      :chain_code
    t.integer     :mol_code
    t.string      :molecule,  :default => ""
    t.boolean     :tainted
    t.text        :cssed_sequence
  end

  # This is for the case sesitivity of 'chain_code' column
  # Please uncomment following line if your default collation is not case sensitive!!!
  #execute "ALTER TABLE chains MODIFY chain_code VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_bin"

  add_index :chains, :chain_code
  add_index :chains, :model_id
  add_index :chains, :tainted


  # 'resdiues' table
  create_table :residues, :force => true do |t|
    t.belongs_to  :chain
    t.belongs_to  :scop
    t.belongs_to  :chain_interface
    t.belongs_to  :domain_interface
    t.belongs_to  :res_map
    t.belongs_to  :residue_map
    t.string      :type
    t.string      :icode
    t.integer     :residue_code
    t.string      :residue_name
    t.float       :unbound_asa
    t.float       :bound_asa
    t.float       :delta_asa
    t.boolean     :ss,                    :default => nil
    t.integer     :hbonds_as_donor_count,    :default => nil
    t.integer     :hbonds_as_acceptor_count, :default => nil
    t.integer     :whbonds_count,            :default => nil
    t.integer     :vdw_contacts_count,       :default => nil
  end

  add_index :residues, :chain_id
  add_index :residues, :scop_id
  add_index :residues, :domain_interface_id
  add_index :residues, :chain_interface_id
  add_index :residues, :res_map_id
  add_index :residues, :residue_map_id
  add_index :residues, :residue_name
  add_index :residues, :type
  add_index :residues, [:icode, :residue_code]
  add_index :residues, [:chain_id, :icode, :residue_code]
  add_index :residues, [:chain_id, :residue_name]
  add_index :residues, [:chain_id, :scop_id]
  add_index :residues, [:chain_id, :type]


  # 'atoms' table
  create_table :atoms, :force => true do |t|
    t.belongs_to  :residue
    t.string      :type
    t.string      :moiety
    t.integer     :atom_code
    t.string      :atom_name
    t.string      :altloc
    t.float       :x
    t.float       :y
    t.float       :z
    t.float       :occupancy
    t.float       :tempfactor
    t.string      :element
    t.string      :charge
    t.integer     :vdw_contacts_count,        :default => 0
    t.integer     :whbonds_count,             :default => 0
    t.integer     :hbonds_as_donor_count,     :default => 0
    t.integer     :hbonds_as_acceptor_count,  :default => 0
  end

  add_index :atoms, :residue_id
  add_index :atoms, [:residue_id, :type, :atom_code]
  add_index :atoms, [:residue_id, :type, :atom_name]


  # 'dssp' table
  create_table :dssp, :force => true do |t|
    t.belongs_to  :residue
    t.integer     :dssp_number
    t.string      :sse
    t.string      :three_turns
    t.string      :four_turns
    t.string      :five_turns
    t.string      :geometrical_bend
    t.string      :chirality
    t.string      :beta_bridge_label_1
    t.string      :beta_bridge_label_2
    t.integer     :beta_brdige_partner_residue_number_1
    t.integer     :beta_brdige_partner_residue_number_2
    t.string      :beta_sheet_label
    t.integer     :sasa
    t.integer     :nh_o_hbond_1_acceptor
    t.float       :nh_o_hbond_1_energy
    t.integer     :o_hn_hbond_1_donor
    t.float       :o_hn_hbond_1_energy
    t.integer     :nh_o_hbond_2_acceptor
    t.float       :nh_o_hbond_2_energy
    t.integer     :o_hn_hbond_2_donor
    t.float       :o_hn_hbond_2_energy
    t.float       :tco
    t.float       :kappa
    t.float       :alpha
    t.float       :phi
    t.float       :psi
  end

  add_index :dssp, :residue_id
  add_index :dssp, :dssp_number


  # 'naccess' table
  create_table :naccess, :force => true do |t|
    t.belongs_to  :atom
    t.float       :unbound_asa
    t.float       :bound_asa
    t.float       :delta_asa
    t.float       :radius
  end

  add_index :naccess, :atom_id


  # 'potentials' table
  create_table :potentials, :force => true do |t|
    t.belongs_to  :atom
    t.float       :unbound_asa
    t.float       :bound_asa
    t.float       :delta_asa
    t.float       :formal_charge
    t.float       :partial_charge
    t.float       :atom_potential
    t.float       :asa_potential
  end

  add_index :potentials, :atom_id


  # 'vdw_contacts' table
  create_table :vdw_contacts, :force => true do |t|
    t.belongs_to  :atom
    t.belongs_to  :vdw_contacting_atom
    t.float       :distance
  end

  add_index :vdw_contacts, :atom_id
  add_index :vdw_contacts, :vdw_contacting_atom_id
  add_index :vdw_contacts, [:atom_id, :vdw_contacting_atom_id]
  add_index :vdw_contacts, [:vdw_contacting_atom_id, :atom_id]


  # 'hbplus' table
  create_table :hbplus, :force => true do |t|
    t.belongs_to  :donor
    t.belongs_to  :acceptor
    t.float       :da_distance
    t.string      :category
    t.integer     :gap
    t.float       :ca_distance
    t.float       :dha_angle
    t.float       :ha_distance
    t.float       :haaa_angle
    t.float       :daaa_angle
  end

  add_index :hbplus, [:donor_id]
  add_index :hbplus, [:acceptor_id]
  add_index :hbplus, [:donor_id, :acceptor_id]
  add_index :hbplus, [:acceptor_id, :donor_id]


  # 'hbonds' table
  create_table :hbonds, :force => true do |t|
    t.belongs_to  :donor
    t.belongs_to  :acceptor
    t.belongs_to  :hbplus
  end

  add_index :hbonds, :donor_id
  add_index :hbonds, :acceptor_id
  add_index :hbonds, :hbplus_id, :unique => true
  add_index :hbonds, [:donor_id, :acceptor_id]
  add_index :hbonds, [:acceptor_id, :donor_id]


  # 'whbonds' table
  create_table :whbonds, :force => true do |t|
    t.belongs_to :atom
    t.belongs_to :whbonding_atom
    t.belongs_to :water_atom
    t.belongs_to :aa_water_hbond
    t.belongs_to :na_water_hbond
  end

  add_index :whbonds, :atom_id
  add_index :whbonds, :whbonding_atom_id
  add_index :whbonds, :water_atom_id
  add_index :whbonds, :aa_water_hbond_id
  add_index :whbonds, :na_water_hbond_id


  # 'interface' table
  create_table :interfaces, :force => true do |t|
    t.belongs_to  :scop
    t.belongs_to  :chain
    t.string      :type
    t.float       :asa
    t.float       :percent_asa
    t.float       :polarity
    t.integer     :residues_count,            :default => 0
    t.integer     :atoms_count,               :default => 0
    t.integer     :vdw_contacts_count,        :default => 0
    t.integer     :whbonds_count,             :default => 0
    t.integer     :hbonds_count,              :default => 0
    t.integer     :hbonds_as_donor_count,     :default => 0
    t.integer     :hbonds_as_acceptor_count,  :default => 0

    AminoAcids::Residues::STANDARD.each do |aa|
      t.float :"residue_propensity_of_#{aa.downcase}"
      t.float :"residue_percentage_of_#{aa.downcase}"
    end

    Sses::ALL.each do |sse|
      t.float :"sse_propensity_of_#{sse.downcase}"
      t.float :"sse_percentage_of_#{sse.downcase}"
    end

    %w(hbond whbond vdw_contact).each do |intact|
      %w(sugar phosphate).each do |moiety|
        t.integer :"frequency_of_#{intact}_between_amino_acids_and_#{moiety}"
      end
      AminoAcids::Residues::STANDARD.each do |aa|
        t.integer :"frequency_of_#{intact}_between_#{aa.downcase}_and_nucleic_acids"

        %w(sugar phosphate).each do |moiety|
          t.integer :"frequency_of_#{intact}_between_#{aa.downcase}_and_#{moiety}"
        end
      end
      %w(dna rna).each do |na|
        na_residues = "NucleicAcids::#{na.camelize}::Residues::STANDARD".constantize
        na_residues.each do |nar|
          t.integer :"frequency_of_#{intact}_between_amino_acids_and_#{nar.downcase}"
          AminoAcids::Residues::STANDARD.each do |aa|
            t.integer :"frequency_of_#{intact}_between_#{aa.downcase}_and_#{nar.downcase}"
          end
        end
      end
    end
  end

  add_index :interfaces, :scop_id
  add_index :interfaces, :chain_id
  add_index :interfaces, [:id, :scop_id]
  add_index :interfaces, [:id, :chain_id]
  add_index :interfaces, [:scop_id, :type]
  add_index :interfaces, [:chain_id, :type]


  # 'subfamilies' table
  create_table :subfamilies, :force => true do |t|
    t.belongs_to  :scop
    t.string      :type
  end

  add_index :subfamilies, :scop_id
  add_index :subfamilies, [:scop_id, :type]


  # 'alignments' table
  create_table :alignments, :force => true do |t|
    t.belongs_to  :scop
    t.belongs_to  :subfamily
    t.string      :type
  end

  add_index :alignments, :scop_id
  add_index :alignments, :subfamily_id
  add_index :alignments, [:scop_id, :type]
  add_index :alignments, [:subfamily_id, :type]


  # 'sequneces' table
  create_table :sequences, :force => true do |t|
    t.belongs_to  :alignment
    t.belongs_to  :scop
    t.belongs_to  :chain
    t.text        :cssed_sequence
  end

  add_index :sequences, :alignment_id
  add_index :sequences, :scop_id
  add_index :sequences, :chain_id


  # 'columns' table
  create_table :columns, :force => true do |t|
    t.belongs_to  :alignment
    t.integer     :number
    t.float       :entropy
    t.float       :relative_entropy
  end

  add_index :columns, :alignment_id
  add_index :columns, [:alignment_id, :number]


  # 'positions' table
  create_table :positions, :force => true do |t|
    t.belongs_to  :sequence
    t.belongs_to  :column
    t.belongs_to  :residue
    t.integer     :number
    t.string      :residue_name
  end

  add_index :positions, :sequence_id
  add_index :positions, [:sequence_id, :number]
  add_index :positions, :column_id
  add_index :positions, :residue_id


  create_table :go_terms, :force => true do |t|
    t.string  :go_id
    t.boolean :is_anonymous,  :default => false
    t.string  :name
    t.string  :namespace
    t.string  :definition
    t.string  :comment
    t.boolean :is_obsolete,   :default => false
    t.boolean :registered,    :default => false
  end

  add_index :go_terms, :go_id, :unique => true
  add_index :go_terms, :is_obsolete
  add_index :go_terms, :registered


  create_table :go_relationships, :force => true do |t|
    t.belongs_to  :source
    t.belongs_to  :target
    t.string      :type
  end

  add_index :go_relationships, :source_id
  add_index :go_relationships, :target_id
  add_index :go_relationships, :type
  add_index :go_relationships, [:source_id, :target_id]
  add_index :go_relationships, [:target_id, :source_id]


  create_table :goa_pdbs, :force => true do |t|
    t.belongs_to  :chain
    t.belongs_to  :go_term
    t.string      :db
    t.string      :db_object_id
    t.string      :db_object_symbol
    t.string      :qualifier
    t.string      :go_id
    t.string      :db_reference
    t.string      :evidence
    t.string      :with
    t.string      :aspect
    t.string      :db_object_name
    t.string      :synonym
    t.string      :db_object_type
    t.integer     :taxon_id
    t.date        :date
    t.string      :assigned_by
  end

  # This is for the case sesitivity of 'db_object_id' and 'db_object_symbol' columns
  # Please uncomment following line if your default collation is not case sensitive!!!
  #execute "ALTER TABLE goa_pdbs MODIFY db_object_id     VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_bin"
  #execute "ALTER TABLE goa_pdbs MODIFY db_object_symbol VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_bin"

  add_index :goa_pdbs, :chain_id
  add_index :goa_pdbs, :go_term_id
  add_index :goa_pdbs, :go_id


  create_table :taxonomic_nodes, :force => true do |t|
    t.integer     :parent_id
    t.string      :rank
    t.string      :embl_code
    t.integer     :division_id
    t.boolean     :inherited_div_flag
    t.integer     :genetic_code_id
    t.boolean     :inherited_gc_flag
    t.integer     :mitochondrial_genetic_code_id
    t.boolean     :inherited_mgc_flag
    t.boolean     :genbank_hidden_flag
    t.boolean     :hidden_subtree_root
    t.string      :comments
    t.boolean     :registered,    :default => false
  end

  add_index :taxonomic_nodes, :parent_id


  create_table :taxonomic_names, :force => true do |t|
    t.belongs_to  :taxonomic_node
    t.string      :name_txt
    t.string      :unique_name
    t.string      :name_class
  end

  add_index :taxonomic_names, :taxonomic_node_id


  create_table :news, :force => true do |t|
    t.date    :date
    t.string  :title
    t.text    :content
  end

  add_index :news, :date


#  create_table :essts, :force => true do |t|
#    t.string  :type
#    t.integer :redundancy
#    t.integer :number
#    t.string  :environment
#    t.string  :secondary_structure
#    t.string  :solvent_accessibility
#    t.string  :hbond_to_sidechain
#    t.string  :hbond_to_mainchain_carbonyl
#    t.string  :hbond_to_mainchain_amide
#    t.string  :dna_rna_interface
#  end
#
#  # This is for the case sesitivity of 'essts' table
#  # Please uncomment following line if your default collation is not case sensitive!!!
#  #execute "ALTER TABLE essts CONVERT TO CHARACTER SET utf8 COLLATE utf8_bin"
#
#  add_index :essts, [:redundancy, :number]
#  add_index :essts, [:environment]


#  create_table :substitutions, :force => true do |t|
#    t.belongs_to  :esst
#    t.string      :aa1
#    t.string      :aa2
#    t.float       :prob
#    t.integer     :log
#    t.integer     :cnt
#  end
#
#  add_index :substitutions, :esst_id


#  create_table :profiles, :force => true do |t|
#    t.belongs_to  :alignment
#    t.string      :type
#    t.string      :name
#    t.string      :command
#    t.integer     :length
#    t.integer     :no_sequences
#    t.integer     :no_structures
#    t.integer     :enhance_num
#    t.float       :enhance_div
#    t.integer     :weighting
#    t.float       :weighting_threshold
#    t.integer     :weighting_seed
#    t.float       :multiple_factor
#    t.string      :format
#    t.string      :similarity_matrix
#    t.string      :similarity_matrix_offset
#    t.string      :ignore_gap_weight
#    t.string      :symbol_in_row
#    t.string      :symbol_in_column
#    t.string      :symbol_structural_feature
#    t.integer     :gap_ins_open_terminal
#    t.integer     :gap_del_open_terminal
#    t.integer     :gap_ins_ext_terminal
#    t.integer     :gap_del_ext_terminal
#    t.integer     :evd
#  end
#
#  add_index :profiles, :alignment_id


#  create_table :profile_columns, :force => true do |t|
#    t.belongs_to  :profile
#    t.belongs_to  :column
#    t.string      :type
#    t.string      :seq
#    t.integer     :aa_A, :aa_C, :aa_D, :aa_E, :aa_F, :aa_G, :aa_H, :aa_I, :aa_K, :aa_L, :aa_M,
#                  :aa_N, :aa_P, :aa_Q, :aa_R, :aa_S, :aa_T, :aa_V, :aa_W, :aa_Y, :aa_J, :aa_U
#    t.integer     :InsO, :InsE, :DelO, :DelE, :COIL, :HNcp, :HCcp, :HIn, :SNcp, :SCcp, :SInt, :NRes, :Ooi, :Acc
#    t.integer     :H, :E, :P, :C, :At, :Af, :St, :Sf, :Ot, :Of, :Nt, :Nf, :D, :R, :N
#  end
#
#  add_index :profile_columns, :profile_id
#  add_index :profile_columns, :column_id

  # This is for the case sesitivity of 'profile_columns' table
  # Please uncomment following line if your default collation is not case sensitive!!!
  #execute "ALTER TABLE profile_columns CONVERT TO CHARACTER SET utf8 COLLATE utf8_bin"


#  create_table :fugue_hits, :force => true do |t|
#    t.belongs_to  :profile
#    t.belongs_to  :scop
#    t.string      :type
#    t.string      :name
#    t.integer     :raws
#    t.integer     :rvn
#    t.float       :zscore
#    t.float       :zori
#    t.boolean     :fam_tp
#    t.boolean     :fam_fp
#    t.boolean     :fam_tn
#    t.boolean     :fam_fn
#    t.boolean     :supfam_tp
#    t.boolean     :supfam_fp
#    t.boolean     :supfam_tn
#    t.boolean     :supfam_fn
#  end
#
#  add_index :fugue_hits, :profile_id
#  add_index :fugue_hits, :scop_id
#  add_index :fugue_hits, :zscore


#  create_table :reference_alignments, :force => true do |t|
#    t.belongs_to  :alignment
#    t.belongs_to  :template
#    t.belongs_to  :target
#    t.float       :pid1
#    t.float       :pid2
#    t.float       :pid3
#    t.float       :pid4
#  end
#
#  add_index :reference_alignments, :alignment_id
#  add_index :reference_alignments, [:template_id, :target_id]


#  create_table :test_alignments, :force => true do |t|
#    t.belongs_to  :reference_alignment
#    t.string      :type
#    t.float       :sp
#    t.float       :tc
#  end
#
#  add_index :test_alignments, :reference_alignment_id
#  add_index :test_alignments, :sp
#  add_index :test_alignments, :tc


  create_table :interface_similarities, :force => true do |t|
    t.belongs_to  :interface
    t.belongs_to  :similar_interface
    t.float       :usr_score
  end

  add_index :interface_similarities, [:interface_id, :similar_interface_id, :usr_score], :unique => true, :name => "by_int_id_and_sim_int_id"
  add_index :interface_similarities, [:similar_interface_id, :interface_id, :usr_score], :unique => true, :name => "by_sim_int_id_and_int_id"


#  create_table :interface_searches, :force => true do |t|
#    t.string    :interface_type
#    t.float     :max_asa,                 :default => 10000.0
#    t.float     :min_asa,                 :default => 0.0
#    t.float     :max_polarity,            :default => 1.0
#    t.float     :min_polarity,            :default => 0.0
#    t.integer   :max_residues_count,      :default => 200
#    t.integer   :min_residues_count,      :default => 0
#    t.integer   :max_atoms_count,         :default => 2000
#    t.integer   :min_atoms_count,         :default => 0
#    t.integer   :max_hbonds_count,        :default => 100
#    t.integer   :min_hbonds_count,        :default => 0
#    t.integer   :max_whbonds_count,       :default => 100
#    t.integer   :min_whbonds_count,       :default => 0
#    t.integer   :max_vdw_contacts_count,  :default => 2000
#    t.integer   :min_vdw_contacts_count,  :default => 0
#
#    AminoAcids::Residues::STANDARD.each do |aa|
#      t.float :"max_residue_percentage_of_#{aa.downcase}", :default => 1.0
#      t.float :"min_residue_percentage_of_#{aa.downcase}", :default => 0.0
#    end
#
#    Sses::ALL.each do |sse|
#      t.float :"max_sse_percentage_of_#{sse.downcase}", :default => 1.0
#      t.float :"min_sse_percentage_of_#{sse.downcase}", :default => 0.0
#    end
#  end


#  create_table :fugue_searches, :force => true do |t|
#    t.string    :type
#    t.string    :name,        :default => nil
#    t.string    :email
#    t.string    :definition,  :default => nil
#    t.integer   :toprank,     :default => 10
#    t.text      :sequence
#    t.text      :result,      :default => nil
#    t.timestamp :started_at, :finished_at
#    t.timestamps
#  end


#  # For RudeQ
#  # http://github.com/matthewrudy/rudeq/tree/master
#  create_table :rude_queues, :force => true do |t|
#    t.string  :queue_name
#    t.text    :data
#    t.string  :token,     :default => nil
#    t.boolean :processed, :default => false, :null => false
#    t.timestamps
#  end
#  add_index :rude_queues, :processed
#  add_index :rude_queues, [:queue_name, :processed]

end
