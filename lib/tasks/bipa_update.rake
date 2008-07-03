namespace :bipa do
  namespace :update do

    require "logger"

    $logger = Logger.new(STDOUT)


    desc "Update ASA related fields of the 'atoms' table"
    task :asa => [:environment] do

      pdb_codes = Structure.find(:all, :select => "pdb_code").map(&:pdb_code)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        pdb_codes.each_with_index do |pdb_code, i|

          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)

            structure = Structure.find_by_pdb_code(pdb_code)

            # Load NACCESS results for every atom in the structure
            bound_asa_file      = File.join(NACCESS_DIR, "#{pdb_code}_co.asa")
            unbound_aa_asa_file = File.join(NACCESS_DIR, "#{pdb_code}_aa.asa")
            unbound_na_asa_file = File.join(NACCESS_DIR, "#{pdb_code}_na.asa")

            bound_atom_asa      = Bipa::Naccess.new(IO.read(bound_asa_file)).atom_asa
            unbound_aa_atom_asa = Bipa::Naccess.new(IO.read(unbound_aa_asa_file)).atom_asa
            unbound_na_atom_asa = Bipa::Naccess.new(IO.read(unbound_na_asa_file)).atom_asa

            structure.aa_atoms.each do |atom|
              if (bound_atom_asa[atom.atom_code] &&
                  unbound_aa_atom_asa[atom.atom_code])
                atom.bound_asa    = bound_atom_asa[atom.atom_code]
                atom.unbound_asa  = unbound_aa_atom_asa[atom.atom_code]
                atom.delta_asa    = atom.unbound_asa - atom.bound_asa
                atom.save!
              end
            end

            structure.na_atoms.each do |atom|
              if (bound_atom_asa[atom.atom_code] &&
                  unbound_na_atom_asa[atom.atom_code])
                atom.bound_asa    = bound_atom_asa[atom.atom_code]
                atom.unbound_asa  = unbound_na_atom_asa[atom.atom_code]
                atom.delta_asa    = atom.unbound_asa - atom.bound_asa
                atom.save!
              end
            end

            $logger.info("Updating ASAs of #{pdb_file}: done (#{i + 1}/#{pdb_codes.size})")
            ActiveRecord::Base.remove_connection
          end # fmanager.fork
        end # pdb_codes.each_with_index
        ActiveRecord::Base.establish_connection(config)
      end # fmanager.manage
    end # task :asa


    desc "Update electrostatic potential related fields of the 'atoms' table"
    task :potential => [:environment] do

      pdb_codes = Structure.find(:all, :select => "pdb_code").map(&:pdb_code)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        pdb_codes.each_with_index do |pdb_code, i|

          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)

            structure = Structure.find_by_pdb_code(pdb_code)
            ZapAtom   = Struct.new(:index, :serial, :symbol, :radius,
                                   :formal_charge, :partial_charge, :potential)

            %w(aa na).each do |mol|
              eval <<-END
                #{mol}_zap_file   = File.join(ZAP_DIR, "#{pdb_code}_#{mol}.zap")
                #{mol}_zap_atoms  = Hash.new

                IO.foreach(#{mol}_zap_file) do |line|
                  elems = line.chomp.split(/\\s+/)
                  next unless elems.size == 7
                  zap = ZapAtom.new(elems)
                  #{mol}_zap_atoms[zap[:serial]] = zap
                end

                structure.#{mol}_atoms.each do |atom|
                  next unless #{mol}_zap_atoms[atom.atom_code]
                  zap_atom            = #{mol}_zap_atoms[atom.atom_code]
                  atom.radius         = zap_atom[:radius]
                  atom.formal_charge  = zap_atom[:formal_charge]
                  atom.partial_charge = zap_atom[:partial_charge]
                  atom.potential      = zap_atom[:potential]
                  atom.save!
                end
              END
            end

            $logger.info("Updating ASAs of #{pdb_file}: done (#{i + 1}/#{pdb_codes.size})")
            ActiveRecord::Base.remove_connection
          end # fmanager.fork
        end # pdb_codes.each_with_index
        ActiveRecord::Base.establish_connection(config)
      end # fmanager.manage
    end # task :asa


    desc "Update chain's mole_code, molecule fields"
    task :chain => [:environment] do
      structures = Structure.find(:all)

      structures.each do |structure|
        pdb_bio   = Bio::PDB.new(IO.read("./public/pdb/#{structure.pdb_code.downcase}.pdb"))
        mol_codes = {}
        molecules = {}
        mol_id    = nil
        molecule  = nil

        pdb_bio.record("COMPND")[0].compound.each do |key, value|
          case
          when key == "MOL_ID"
            mol_id = value
          when key == "MOLECULE"
            molecule = value
          when key == "CHAIN"
            mol_codes[value] = mol_id
            molecules[value] = molecule
          end
        end

        structure.models.first.chains.each do |chain|
          c = chain.chain_code
          chain.mol_code = mol_codes[c] ? mol_codes[c] : nil
          chain.molecule = molecules[c] ? molecules[c] : nil
          puts "#{chain.mol_code}: #{chain.molecule}"
          #chain.save!
        end
      end
    end


    desc "Update 'chains_count' column of 'models' table"
    task :models_chains_count => [:environment] do
      models = Model.find(:all)
      models.each_with_index do |model, i|
        model.update_attribute :chains_count, model.chains.length
        $logger.info("Updating 'chains_count' column of 'models' table, #{model.id}: done (#{i+1}/#{models.size})")
      end
    end


    desc "Update 'aa_chains_count' column of 'models' table"
    task :models_aa_chains_count => [:environment] do
      models = Model.find(:all)
      models.each_with_index do |model, i|
        model.update_attribute :aa_chains_count, model.aa_chains.length
        $logger.info("Updating 'aa_chains_count' column of 'models' table, #{model.id}: done (#{i+1}/#{models.size})")
      end
    end


    desc "Update 'na_chains_count' column of 'models' table"
    task :models_na_chains_count => [:environment] do
      models = Model.find(:all)
      models.each_with_index do |model, i|
        model.update_attribute :na_chains_count, model.na_chains.length
        $logger.info("Updating 'na_chains_count' column of 'models' table, #{model.id}: done (#{i+1}/#{models.size})")
      end
    end


    desc "Update 'dna_chains_count' column of 'models' table"
    task :models_dna_chains_count => [:environment] do
      models = Model.find(:all)
      models.each_with_index do |model, i|
        model.update_attribute :dna_chains_count, model.dna_chains.length
        $logger.info("Updating 'dna_chains_count' column of 'models' table, #{model.id}: done (#{i+1}/#{models.size})")
      end
    end


    desc "Update 'rna_chains_count' column of 'models' table"
    task :models_rna_chains_count => [:environment] do
      models = Model.find(:all)
      models.each_with_index do |model, i|
        model.update_attribute :rna_chains_count, model.rna_chains.length
        $logger.info("Updating 'rna_chains_count' column of 'models' table, #{model.id}: done (#{i+1}/#{models.size})")
      end
    end


    desc "Update 'hna_chains_count' column of 'models' table"
    task :models_hna_chains_count => [:environment] do
      models = Model.find(:all)
      models.each_with_index do |model, i|
        model.update_attribute :hna_chains_count, model.hna_chains.length
        $logger.info("Updating 'hna_chains_count' column of 'models' table, #{model.id}: done (#{i+1}/#{models.size})")
      end
    end


    desc "Update 'pseudo_chains_count' column of 'models' table"
    task :models_pseudo_chains_count => [:environment] do
      models = Model.find(:all)
      models.each_with_index do |model, i|
        model.update_attribute :pseudo_chains_count, model.pseudo_chains.length
        $logger.info("Updating 'pseudo_chains_count' column of 'models' table, #{model.id}: done (#{i+1}/#{models.size})")
      end
    end


    desc "Update 'contacts_count' column of 'atoms' table"
    task :atoms_contacts_count => [:environment] do
      Atom.find_all_in_chunks(:select => "id, contacts_count", :per_page => 10000) do |atom|
        atom.update_attribute :contacts_count, atom.contacts.length
      end
    end


    desc "Update 'whbonds_count' column of 'atoms' table"
    task :atoms_whbonds_count => [:environment] do
      Atom.find_all_in_chunks(:select => "id, whbonds_count", :per_page => 10000) do |atom|
        atom.update_attribute :whbonds_count, atom.whbonds.length
      end
    end


    desc "Update 'hbonds_as_donor_count' column of 'atoms' table"
    task :atoms_hbonds_as_donor_count => [:environment] do
      Atom.find_all_in_chunks(:select => "id, hbonds_as_donor_count", :per_page => 10000) do |atom|
        atom.update_attribute :hbonds_as_donor_count, atom.hbonds_as_donor.length
      end
    end


    desc "Update 'hbonds_as_acceptor_count' column of 'atoms' table"
    task :atoms_hbonds_as_acceptor_count => [:environment] do
      Atom.find_all_in_chunks(:select => "id, hbonds_as_acceptor_count", :per_page => 10000) do |atom|
        atom.update_attribute :hbonds_as_acceptor_count, atom.hbonds_as_acceptor.length
      end
    end


    desc "Update 'residues_count' column of 'interfaces' table"
    task :interfaces_residues_count => [:environment] do
      DomainInterface.find_all_in_chunks(:select => "id, residues_count") do |interface|
        interface.update_attribute :residues_count, interface.residues.length
      end
    end


    desc "Update 'atoms_count' column of 'interfaces' table"
    task :interfaces_atoms_count => [:environment] do
      DomainInterface.find_all_in_chunks(:select => "id, atoms_count") do |interface|
        interface.update_attribute :atoms_count, interface.atoms.length
      end
    end


    desc "Update 'contacts_count' column of 'interfaces' table"
    task :interfaces_contacts_count => [:environment] do
      DomainInterface.find_all_in_chunks(:select => "id, contacts_count") do |interface|
        interface.update_attribute :contacts_count, interface.contacts.length
      end
    end


    desc "Update 'whbonds_count' column of 'interfaces' table"
    task :interfaces_whbonds_count => [:environment] do
      DomainInterface.find_all_in_chunks(:select => "id, whbonds_count") do |interface|
        interface.update_attribute :whbonds_count, interface.whbonds.length
      end
    end


    desc "Update 'hbonds_as_donor_count' column of 'interfaces' table"
    task :interfaces_hbonds_as_donor_count => [:environment] do
      DomainInterface.find_all_in_chunks(:select => "id, hbonds_as_donor_count") do |interface|
        interface.update_attribute :hbonds_as_donor_count, interface.hbonds_as_donor.length
      end
    end


    desc "Update 'hbonds_as_acceptor_count' column of 'interfaces' table"
    task :interfaces_hbonds_as_acceptor_count => [:environment] do
      DomainInterface.find_all_in_chunks(:select => "id, hbonds_as_acceptor_count") do |interface|
        interface.update_attribute :hbonds_as_acceptor_count, interface.hbonds_as_acceptor.length
      end
    end


    desc "Update 'hbonds_count' column of 'interfaces' table"
    task :interfaces_hbonds_count => [:environment] do
      DomainInterface.find_all_in_chunks(:select => "id, hbonds_count") do |interface|
        interface.update_attribute :hbonds_count, interface.hbonds_as_donor.length + interface.hbonds_as_acceptor.length
      end
    end


    desc "Update 'repXXX' columns of 'scops' table"
    task :scops_reps => [:environment] do
      (10..100).step(10).each do |si|
        klass = "Rep#{si}Subfamily".constantize
        klass.find(:all).each do |subfamily|
          rep = subfamily.representative
          unless rep.nil?
            rep.send("rep#{si}=", true)
            rep.save!
            rep.ancestors.each do |anc|
              anc.send("rep#{si}=", true)
              anc.save!
            end
            $logger.info("Updating representative structure, #{rep.id} for #{klass}, #{subfamily.id}: done")
          else
            $logger.info("No representative structure for Rep#{si}Subfamily, #{subfamily.id}")
          end
        end
      end
    end


    desc "Update 'resXXX' columns of 'scops' table"
    task :scops_reses => [:environment] do
      domains = ScopDomain.repall.find(:all)

      domains.each_with_index do |domain, i|
        domain.res1    = true if domain.resolution < 1
        domain.res2    = true if domain.resolution < 2
        domain.res3    = true if domain.resolution < 3
        domain.res4    = true if domain.resolution < 4
        domain.res5    = true if domain.resolution < 5
        domain.res6    = true if domain.resolution < 6
        domain.res7    = true if domain.resolution < 7
        domain.res8    = true if domain.resolution < 8
        domain.res9    = true if domain.resolution < 9
        domain.res10   = true if domain.resolution < 10
        domain.resall  = true if domain.resolution < 1000

        domain.save!

        domain.ancestors.each do |ancestor|
          ancestor.res1    = true if domain.res1    == true
          ancestor.res2    = true if domain.res2    == true
          ancestor.res3    = true if domain.res3    == true
          ancestor.res4    = true if domain.res4    == true
          ancestor.res5    = true if domain.res5    == true
          ancestor.res6    = true if domain.res6    == true
          ancestor.res7    = true if domain.res7    == true
          ancestor.res8    = true if domain.res8    == true
          ancestor.res9    = true if domain.res9    == true
          ancestor.res10   = true if domain.res10   == true
          ancestor.resall  = true if domain.resall  == true

          ancestor.save!
        end

        $logger.info("Processing #{domain.id} : done (#{i+1}/#{domains.size})")
      end
    end


    desc "Update 'resolution' column of 'scop' table"
    task :scops_resolution => [:environment] do
      domains = ScopDomain.repall.find(:all)
      domains.each_with_index do |domain, i|
        resolution = domain.chains.first.model.structure.resolution
        if resolution.nil?
          domain.update_attribute(:resolution, 999.0)
        else
          domain.update_attribute(:resolution, resolution)
        end
        domain.save!
        $logger.info("Updating resolution, #{domain.resolution} of domain, #{domain.id}: done (#{i+1}/#{domains.size})")
      end
    end


    desc "Update JOY templates to include atomic interaction information"
    task :joy_templates => [:environment] do

      Dir["./public/families/rep90/*"].grep(/\d+/).each_with_index do |dir, i|
        sunid = dir.match(/rep\d+\/(\d+)/)[1]
        tem_file = File.join(dir, "baton.tem")

        if File.size? tem_file
          new_tem_file = File.join(dir, "#{sunid}.tem")

          cp tem_file, new_tem_file

          flat_file = Bio::FlatFile.auto(tem_file)
          flat_file.each_entry do |entry|

            if entry.seq_type == "P1" && entry.definition == "sequence"
              domain = ScopDomain.find_by_sunid(entry.entry_id)

              if domain.nil?
                warn "Cannot find #{entry.entry_id} from BIPA"
                exit
              end

              hbond_tem   = []
              whbond_tem  = []
              contact_tem = []
              db_residues = domain.residues
              ff_residues = entry.data.gsub(/\n/, "").split("")

              pos = 0

              ff_residues.each_with_index do |res, fi|
                if fi % 75 == 0
                  hbond_tem << "\n"
                  whbond_tem << "\n"
                  contact_tem << "\n"
                end

                if res == "-"
                  hbond_tem << "-"
                  whbond_tem << "-"
                  contact_tem << "-"
                  next
                else
                  if res == db_residues[pos].one_letter_code
                    db_residues[pos].hbonding_na? ? hbond_tem << "T" : hbond_tem << "F"
                    db_residues[pos].whbonding_na? ? whbond_tem << "T" : whbond_tem << "F"
                    db_residues[pos].contacting_na? ? contact_tem << "T" : contact_tem << "F"
                    pos += 1
                  else
                    warn "Unmatched residues at #{pos} of #{entry.entry_id}, #{res} <=> #{db_residues[pos].one_letter_code}"
                    exit
                  end
                end
              end

              File.open(new_tem_file, "a") do |file|
                file.puts ">P1;#{entry.entry_id}"
                file.puts "hydrogen bond to nucleic acid"
                file.puts hbond_tem.join + "*"

                file.puts ">P1;#{entry.entry_id}"
                file.puts "water-mediated hydrogen bond to nucleic acid"
                file.puts whbond_tem.join + "*"

                file.puts ">P1;#{entry.entry_id}"
                file.puts "van der Waals contact to nucleic acid"
                file.puts contact_tem.join + "*"
              end
            end
          end
          $logger.info "Updateing JOY template of SCOP family, #{sunid}: done"
        else
          $logger.warn "Cannot find 'baton.tem' of SCOP family, #{sunid}"
        end
      end
    end

  end
end
