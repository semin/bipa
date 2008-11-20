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

            %w[aa na].each do |mol|
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


    desc "Update 'vdw_contacts_count' column of 'atoms' table"
    task :atoms_vdw_contacts_count => [:environment] do
      Atom.find_all_in_chunks(:select => "id, vdw_contacts_count", :per_page => 10000) do |atom|
        atom.update_attribute :vdw_contacts_count, atom.vdw_contacts.length
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


    desc "Update 'vdw_contacts_count' column of 'interfaces' table"
    task :interfaces_vdw_contacts_count => [:environment] do
      DomainInterface.find_all_in_chunks(:select => "id, vdw_contacts_count") do |interface|
        interface.update_attribute :vdw_contacts_count, interface.vdw_contacts.length
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


    desc "Update 'rpXXX' columns of 'scop' table"
    task :scop_rp => [:environment] do
      %w[dna rna].each do |na|
        (20..100).step(20).each do |si|
          klass = "Nr#{si}#{na.capitalize}Subfamily".constantize
          klass.all.each do |subfamily|
            rep = subfamily.representative
            unless rep.nil?
              rep.send("rp#{si}_#{na}=", true)
              rep.save!
              rep.ancestors.each do |anc|
                anc.send("rp#{si}_#{na}=", true)
                anc.save!
              end
              $logger.info ">>> Updating representative structure, #{rep.id} for #{klass}, #{subfamily.id}: done"
            else
              $logger.warn "!!! No representative structure for #{klass}, #{subfamily.id}"
            end
          end
        end
      end
    end


    desc "Update 'rsXXX' columns of 'scops' table"
    task :scop_rs => [:environment] do

      domains = ScopDomain.nrall
      domains.each_with_index do |domain, i|
        domain.rs2    = true if domain.resolution < 2
        domain.rs4    = true if domain.resolution < 4
        domain.rs6    = true if domain.resolution < 6
        domain.rs8    = true if domain.resolution < 8
        domain.rs10   = true if domain.resolution < 10
        domain.rsall  = true if domain.resolution < 1000
        domain.save!

        domain.ancestors.each do |ancestor|
          ancestor.rs2    = true if domain.rs2    == true
          ancestor.rs4    = true if domain.rs4    == true
          ancestor.rs6    = true if domain.rs6    == true
          ancestor.rs8    = true if domain.rs8    == true
          ancestor.rs10   = true if domain.rs10   == true
          ancestor.rsall  = true if domain.rsall  == true
          ancestor.save!
        end

        $logger.info ">>> Updating resolution info of #{domain.id} : done (#{i+1}/#{domains.size})"
      end
    end


    desc "Update JOY templates to include atomic interaction information"
    task :joy_templates => [:environment] do

      %w[dna rna].each do |na|
        fmanager = ForkManager.new(MAX_FORK)
        fmanager.manage do
          config = ActiveRecord::Base.remove_connection

          (20..100).step(20) do |si|
            # CAUTION!!!
            if si != 80
              $logger.warn "!!! Sorry, skipped #{na}#{si} for the moment"
              next
            end

            FileList["./public/families/nr#{si}/#{na}/*"].each do |fam_dir|
              fmanager.fork do
                ActiveRecord::Base.establish_connection(config)

                if fam_dir =~ /#{na}\/(\d+)/
                  sunid = $1
                else
                  $logger.warn "!!! #{fam_dir} is not matched to a certain SCOP sunid"
                  next
                end

                tem_file = File.join(fam_dir, "baton.tem")

                if !File.size? tem_file
                  $logger.warn "!!! Cannot find 'baton.tem' for SCOP family, #{sunid} or it's empty"
                  next
                end

                new_tem_file = File.join(fam_dir, "#{sunid}.tem")
                cp tem_file, new_tem_file

                flat_file = Bio::FlatFile.auto(tem_file)
                flat_file.each_entry do |entry|
                  if entry.seq_type == "P1" && entry.definition == "sequence"
                    domain = ScopDomain.find_by_sunid(entry.entry_id)

                    if domain.nil?
                      $logger.warn "!!! Cannot find #{entry.entry_id} from BIPA"
                      exit
                    end

                    bind_tem        = []
                    hbond_tem       = []
                    whbond_tem      = []
                    vdw_contact_tem = []
                    db_residues     = domain.residues
                    ff_residues     = entry.data.gsub("\n", "").split("")

                    pos = 0

                    ff_residues.each_with_index do |res, fi|
                      if fi != 0 and fi % 75 == 0
                        bind_tem        << "\n"
                        hbond_tem       << "\n"
                        whbond_tem      << "\n"
                        vdw_contact_tem << "\n"
                      end

                      if res == "-"
                        bind_tem        << "-"
                        hbond_tem       << "-"
                        whbond_tem      << "-"
                        vdw_contact_tem << "-"
                        next
                      else
                        if res == db_residues[pos].one_letter_code
                          db_residues[pos].send("binding_#{na}?")         ? bind_tem        << "T" : bind_tem         << "F"
                          db_residues[pos].send("hbonding_#{na}?")        ? hbond_tem       << "T" : hbond_tem        << "F"
                          db_residues[pos].send("whbonding_#{na}?")       ? whbond_tem      << "T" : whbond_tem       << "F"
                          db_residues[pos].send("vdw_contacting_#{na}?")  ? vdw_contact_tem << "T" : vdw_contact_tem  << "F"
                          pos += 1
                        else
                          $logger.warn "!!! Unmatched residues at #{pos} of #{entry.entry_id}, #{res} <=> #{db_residues[pos].one_letter_code}"
                          exit 1
                        end
                      end
                    end

                    File.open(new_tem_file, "a") do |file|
                      file.puts ">P1;#{entry.entry_id}"
                      file.puts "#{na.upcase} interface"
                      file.puts bind_tem.join + "*"

                      file.puts ">P1;#{entry.entry_id}"
                      file.puts "hydrogen bond to #{na.upcase}"
                      file.puts hbond_tem.join + "*"

                      file.puts ">P1;#{entry.entry_id}"
                      file.puts "water-mediated hydrogen bond to #{na.upcase}"
                      file.puts whbond_tem.join + "*"

                      file.puts ">P1;#{entry.entry_id}"
                      file.puts "van der Waals contact to #{na.upcase}"
                      file.puts vdw_contact_tem.join + "*"
                    end
                  end
                end
                ActiveRecord::Base.remove_connection
                $logger.info ">>> Updating JOY template for #{na.upcase} binding NR#{si} SCOP family, #{sunid}: done"
              end
            end
          end
          ActiveRecord::Base.establish_connection(config)
        end
      end
    end


    desc "Filter 'vdw_contacts' table not to contain any hbonds or whbonds"
    task :filter_vdw_contacts => [:environment] do
      i = 0
      puts "Remove hbonds from vdw_contacts"
      Hbond.find_all_in_chunks do |hbond|
        vdw_contact1 = VdwContact.find_by_atom_id_and_vdw_contacting_atom_id(hbond.donor, hbond.acceptor)
        vdw_contact2 = VdwContact.find_by_atom_id_and_vdw_contacting_atom_id(hbond.acceptor, hbond.donor)
        if vdw_contact1
          VdwContact.destroy(vdw_contact1)
          $logger.info ">>> Destroyed vdw contact, #{vdw_contact1.id} (#{i += 1})"
        end
        if vdw_contact2
          VdwContact.destroy(vdw_contact2)
          $logger.info ">>> Destroyed vdw contact, #{vdw_contact2.id} (#{i += 1})"
        end
      end
    end


    desc "Update DNA/RNA interactibility for all residues"
    task :residues_na_interactibility => [:environment] do

      intfs     = DomainInterface.all
      total     = intfs.count
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection
        intfs.each_with_index do |intf, i|
          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)
            %w[dna rna].each do |na|
              intf.residues.each do |aa|
                aa.send("hbond_#{na}_base=",       true) if aa.send("hbonding_#{na}_base_as_donor?") || aa.send("hbonding_#{na}_base_as_acceptor?")
                aa.send("hbond_#{na}_sugar=",      true) if aa.send("hbonding_#{na}_sugar_as_donor?") || aa.send("hbonding_#{na}_sugar_as_acceptor?")
                aa.send("hbond_#{na}_phosphate=",  true) if aa.send("hbonding_#{na}_phosphate_as_donor?") || aa.send("hbonding_#{na}_phosphate_as_acceptor?")
                aa.send("whbond_#{na}_base=",      true) if aa.send("whbond_#{na}_base?")
                aa.send("whbond_#{na}_sugar=",     true) if aa.send("whbond_#{na}_sugar?")
                aa.send("whbond_#{na}_phosphate=", true) if aa.send("whbond_#{na}_phosphate?")
                aa.send("vdw_#{na}_base=",         true) if aa.send("vdw_contacting_#{na}_base?")
                aa.send("vdw_#{na}_sugar=",        true) if aa.send("vdw_contacting_#{na}_sugar?")
                aa.send("vdw_#{na}_phophate=",     true) if aa.send("vdw_contacting_#{na}_phosphate?")
                aa.save!
              end
            end
            $logger.debug ">>> Updating DNA/RNA interactibility for residues in interface, #{intf.id}: done (#{i+1}/#{total})"
            ActiveRecord::Base.remove_connection
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


    #
    # supposed to be updated when importing domain_interfaces!!!
    #
    desc "Update rpall_dna, rpall_rna of 'scop' table"
    task :scop_rpall_na => [:environment] do

      domains = ScopDomain.rpall
      domains.each_with_index do |domain, i|
        %w[dna rna].each do |na|
          if domain.send("#{na}_interfaces").size > 0
            domain.send("rpall_#{na}=", true)
            domain.save!
            domain.ancestors.each do |anc|
              anc.rpall = true
              anc.send("rpall_#{na}=", true)
              anc.save!
            end
          end
        end
        $logger.info ">>> Updating SCOP domain's rpall_dna, rpall_rna: done (#{i + 1}/#{domains.count})"
      end
    end

    desc "Update ASA related fields for 'residues' tabl"
    task :residues_asa => [:environment] do

      pdb_codes = Structure.all.map(&:pdb_code)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection
        pdb_codes.each_with_index do |pdb_code, i|
          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)
            structure = Structure.find_by_pdb_code(pdb_code)
            structure.models.first.std_residues.each do |residue|
              %w[unbound bound delta].each do |state|
                residue.send("#{state}_asa=", residue.send("calculate_#{state}_asa"))
                residue.save!
              end
            end
            $logger.info ">>> Updating Residue ASA fileds for #{structure.pdb_code}: done (#{i + 1}/#{pdb_codes.count})"
            ActiveRecord::Base.remove_connection
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end

  end
end
