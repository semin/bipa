namespace :bipa do
  namespace :import do

    desc "Import protein-nucleic acid complex PDB files to BIPA tables"
    task :pdb => [:environment] do

      pdb_files = Dir[File.join(BIPA_ENV[:PDBNUC_STRUCTURES_DIR], "*.pdb")].sort
      fmanager  = ForkManager.new(BIPA_ENV[:MAX_FORK])

      fmanager.manage do

        config = ActiveRecord::Base.remove_connection

        pdb_files.each_with_index do |pdb_file, i|

          fmanager.fork do

            ActiveRecord::Base.establish_connection config

            pdb_code  = pdb_file.gsub(/\.pdb/, "")
            pdb_bio   = Bio::PDB.new IO.readlines(pdb_file).join

            # Load NACCESS results for every atom in the structure
            bound_asa_file      = File.join(BIPA_ENV[:PDBNUC_NACCESS_DIR], "#{pdb_code}.asa")
            unbound_aa_asa_file = File.join(BIPA_ENV[:PDBNUC_NACCESS_DIR], "#{pdb_code}_aa.asa")
            unbound_na_asa_file = File.join(BIPA_ENV[:PDBNUC_NACCESS_DIR], "#{pdb_code}_na.asa")

            bound_atom_asa      = BIPA::NACCESS.new(IO.readlines(bound_asa_file).join).atom_asa
            unbound_aa_atom_asa = BIPA::NACCESS.new(IO.readlines(unbound_aa_asa_file).join).atom_asa
            unbound_na_atom_asa = BIPA::NACCESS.new(IO.readlines(unbound_na_asa_file).join).atom_asa

            # Load DSSP results for every amino acid residue in the structure
            dssp_file   = File.join(BIPA_ENV[:DSSP_UNCOMPRESSED_DIR], "#{pdb_code}.dssp")
            dssp_sstruc = BIPA::DSSP.new(IO.readlines(dssp_file).join).sstruc

            # Parse molecule and chain information
            # Very dirty... it needs refactoring!
            mol_codes = {}
            molecules = {}

            pdb_bio.record('COMPND')[0].original_data.map do |s|
              s.gsub(/^COMPND\s+\d*\s+/,'').gsub(/\s*$/,'')
            end.join.scan(/MOL_ID:\s+(\d+);MOLECULE:\s+(.*?);CHAIN:\s+(.*?);/) do |mol_id, molecule, chain_codes|
              chain_codes.split(/,/).each do |chain_code|
                chain_code.strip!
                mol_codes[chain_code] = mol_id
                molecules[chain_code] = molecule
              end
            end

            structure = Structure.create!(
              :pdb_code       => pdb_bio.accession,
              :classification => pdb_bio.classification,
              :title          => pdb_bio.definition,
              :exp_method     => pdb_bio.exp_method,
              :resolution     => pdb_bio.resolution,
              :deposited_at   => pdb_bio.deposition_date
            )

            model_bio = pdb_bio.models[0]

            model = Model.create!(
              :structure_id => structure.id,
              :model_code   => model_bio.serial ? model_bio.serial : 1
            )

            # Create empty atoms array for massive importing Atom AREs
            atoms = Array.new

            model_bio.each do |chain_bio|

              chain_code = chain_bio.chain_id.empty? ? '-' : chain_bio.chain_id

              chain_type = case chain_bio
                           when chain_bio.aa?
                             AaChain
                           when chain_bio.dna?
                             DnaChain
                           when chain_bio.rna?
                             RnaChain
                           when chain_bio.hna?
                             HnaChain
                           when chain_bio.het?
                             HetChain
                           end

              chain = chain_type.create!(
                :model_id   => model.id,
                :chain_code => chain_code,
                :mol_code   => mol_codes[chain_code] ? mol_codes[chain_code] : nil,
                :molecule   => molecules[chain_code] ? molecules[chain_code] : nil
              )

              def residue_params(chain_id, residue, sstruc = nil)
                {
                  :chain_id             => chain_id,
                  :residue_code         => residue.residue_id,
                  :icode                => (residue.iCode.empty? ? nil : residue.iCode),
                  :residue_name         => residue.resName,
                  :hydrophobicity       => residue.hydrophobicity,
                  :secondary_structure  => sstruc
                }
              end

              def atom_params(residue_id, atom, bound_asa = nil, unbound_asa = nil)

                delta_asa = unbound_asa - bound_asa if bound_asa && unbound_asa

                {
                  :residue_id     => residue_id,
                  :position_type  => atom.position_type,
                  :atom_code      => atom.serial,
                  :atom_name      => atom.name,
                  :altloc         => atom.altLoc.empty? ? nil : atom.altLoc,
                  :x              => atom.x,
                  :y              => atom.y,
                  :z              => atom.z,
                  :occupancy      => atom.occupancy,
                  :tempfactor     => atom.tempFactor,
                  :element        => atom.element,
                  :charge         => atom.charge.empty? ? nil : atom.charge,
                  :bound_asa      => bound_asa,
                  :unbound_asa    => unbound_asa,
                  :delta_asa      => delta_asa
                }
              end

              # For each standard residue
              chain_bio.each_residue do |residue_bio|

                if residue_bio.is_dna?
                  residue = DnaResidue.create!(residue_params(chain.id, residue_bio))
                elsif residue_bio.is_rna?
                  residue = RnaResidue.create!(residue_params(chain.id, residue_bio))
                else
                  dssp_hash_key = chain_bio.chain_id + residue_bio.residue_id
                  sstruc        = dssp_sstruc[dssp_hash_key].empty? ? 'L' : dssp_sstruc[dssp_hash_key]
                  residue       = AaResidue.create!(residue_params(chain.id, residue_bio, sstruc))
                end

                residue_bio.each do |atom_bio|

                  atoms << Atom.new(
                    atom_params(
                      residue.id,
                      atom_bio,
                      bound_atom_asa[atom_bio.serial],
                      unbound_aa_atom_asa[atom_bio.serial] || unbound_na_atom_asa[atom_bio.serial])
                  )
                end
              end

              chain_bio.each_heterogen do |het_residue_bio|

                het_residue = HetResidue.create!(residue_params(chain.id, het_residue_bio))

                het_residue_bio.each do |het_atom_bio|
                  atoms << Atom.new(atom_params(het_residue.id, het_atom_bio))
                end
              end
            end

            Atom.import(atoms, :validate => false)

            structure.save!

            puts "Importing #{pdb_code_up}, #{pdb_bio.exp_method} (#{i + 1} / #{total_pdb}): done"

            # Remove DB connection for this fork
            ActiveRecord::Base.remove_connection
          end
        end
        # Reconnect to DB for main process
        ActiveRecord::Base.establish_connection(config)
      end
    end # task :pdb

    desc "Import van der Waals Contacts"
    task :contacts => [:environment] do
      structures    = Structure.find_all_by_complete(true)
      pdb_codes     = structures.map { |s| s.pdb_code }
      total_pdb     = structures.size
      fork_manager  = ForkManager.new(BIPA_ENV[:MAX_FORK])

      fork_manager.manage do
        config = ActiveRecord::Base.remove_connection
        pdb_codes.each_with_index do |pdb_code, i|
          fork_manager.fork do
            pdb_file = File.join(BIPA_ENV[:PDB_DIR], "#{pdb_code.downcase}.pdb")
            unless File.exist?(pdb_file)
              puts "Skip #{pdb_code} (#{i + 1}/#{total_pdb}): #{pdb_file} doesn't exist!"
              next
            end

            ActiveRecord::Base.establish_connection(config)

            structure = Structure.find_by_pdb_code(pdb_code)
            if structure.has_complete_contacts
              puts "Skip #{pdb_code} (#{i + 1}/#{total_pdb}): complete contacts already!"
              next
            end

            pdb = Bio::PDB.new(IO.readlines(pdb_file).join)
            kdtree = BIPA::KDTree.new
            aa_points = Array.new

            pdb.models.first.each do |chain|
              next if chain.chain_id =~ /^\s*$/
                chain.each do |residue|
                type = case
                       when residue.is_na?
                         :na
                       when residue.is_aa?
                         :aa
                       else
                         raise "Unknown type of residue!"
                       end
                residue.each do |atom|
                  point = BIPA::Point.new(atom.x, atom.y, atom.z, atom.serial, type)
                  kdtree.insert(point)
                  aa_points << point if type ==:aa
                end
                end
            end

            contacts = Array.new

            for aa_point in aa_points
              neighbors = kdtree.neighbors(aa_point, BIPA_ENV[:MAX_DISTANCE])
              for neighbor in neighbors
                if neighbor.point.type == :na
                  dist    = aa_point - neighbor.point
                  aa_atom = structure.atoms.find_by_atom_code(aa_point.serial)
                  na_atom = structure.atoms.find_by_atom_code(neighbor.point.serial)
                  contacts << [aa_atom[:id], na_atom[:id], dist]
                end
              end
            end

            columns = [:atom_id, :contacting_atom_id, :distance]
            Contact.import(columns, contacts)

            structure.has_complete_contacts = true
            structure.save!
            puts "Importing CONTACTS in #{pdb_code} (#{i + 1}/#{total_pdb}): done"

            ActiveRecord::Base.remove_connection
          end # fork_manager.fork
        end # pdb_codes.each_with_index
        ActiveRecord::Base.establish_connection(config)
      end # fork_manager.manage
    end

    desc "Import Hydrogen Bonds"
    task :hbonds => [:environment] do
      structures  = Structure.find_all_by_complete(true)
      pdb_codes   = structures.map {|s| s.pdb_code}
      total_pdb   = structures.size

      fork_manager = ForkManager.new(BIPA_ENV[:MAX_FORK])
      fork_manager.manage do
        config = ActiveRecord::Base.remove_connection
        pdb_codes.each_with_index do |pdb_code, i|
          fork_manager.fork do

            hbplus_file = File.join(BIPA_ENV[:HBPLUS_DIR], "#{pdb_code.downcase}.hb2")
            unless File.exist?(hbplus_file)
              puts "Skip #{pdb_code} (#{i + 1}/#{total_pdb}): #{hbplus_file} doesn't exist!"
              next
            end

            ActiveRecord::Base.establish_connection(config)
            structure = Structure.find_by_pdb_code(pdb_code)

            if structure.has_complete_hbonds
              puts "Skip #{pdb_code} (#{i + 1}/#{total_pdb}): complete hbonds already!"
              next
            end
            hbonds = Array.new
            hbonds_bipa = BIPA::HBPlus.new(IO.readlines(hbplus_file).join).hbonds

            hbonds_bipa.each do |hbond|
              if ((hbond.donor.is_aa? && hbond.acceptor.is_na?) || (hbond.donor.is_na? && hbond.acceptor.is_aa?))
                begin
                  donor_atom = structure.models[0].chains.find_by_chain_code(hbond.donor.chain_code).residues.find_by_residue_code_and_icode(hbond.donor.residue_code, hbond.donor.insertion_code).atoms.find_by_atom_name(hbond.donor.atom_name)
                  acceptor_atom = structure.models[0].chains.find_by_chain_code(hbond.acceptor.chain_code).residues.find_by_residue_code_and_icode(hbond.acceptor.residue_code, hbond.acceptor.insertion_code).atoms.find_by_atom_name(hbond.acceptor.atom_name)
                rescue
                  puts "Cannot find #{pdb_code}: #{hbond.donor} <=> #{hbond.acceptor}!"
                  next
                else
                  if donor_atom && acceptor_atom
                    hbonds << [
                      donor_atom[:id], acceptor_atom[:id], hbond.da_distance,
                      hbond.category, hbond.gap, hbond.ca_distance, hbond.dha_angle,
                      hbond.ha_distance, hbond.haaa_angle, hbond.daaa_angle
                    ]
                  end
                end
              end
            end

            columns = [
              :hbonding_donor_id, :hbonding_acceptor_id,
              :da_distance, :category, :gap, :ca_distance,
              :dha_angle, :ha_distance, :haaa_angle, :daaa_angle
            ]

            Hbond.import(columns, hbonds)
            # Tag for presence/absence of hbonds
            if hbonds.size > 0
              structure.has_complete_hbonds = true
              structure.save!
            end
            puts "Importing HBONDS in #{pdb_code} (#{i + 1}/#{total_pdb}): done"
            ActiveRecord::Base.remove_connection
          end # fork_manager.fork
        end # pdb_codes.each_with_index
        ActiveRecord::Base.establish_connection(config)
      end # fork_manager.manage
    end

    desc "Import Water-mediated hydrogen bonds"
    task :whbonds => [:environment] do
      structures  = Structure.find_all_by_complete(true)
      pdb_codes   = structures.map {|s| s.pdb_code}
      total_pdb   = structures.size

      # Create fork manager for concurrent fetching
      fork_manager = ForkManager.new(BIPA_ENV[:MAX_FORK])
      fork_manager.manage do
        config = ActiveRecord::Base.remove_connection
        pdb_codes.each_with_index do |pdb_code, i|
          fork_manager.fork do

            hbplus_file = File.join(BIPA_ENV[:HBPLUS_DIR], "#{pdb_code.downcase}.hb2")
            unless File.exist?(hbplus_file)
              puts "Skip #{pdb_code} (#{i + 1}/#{total_pdb}): #{hbplus_file} doesn't exist!"
              next
            end

            ActiveRecord::Base.establish_connection(config)

            structure = Structure.find_by_pdb_code(pdb_code)

            if structure.has_complete_whbonds
              puts "Skip #{pdb_code} (#{i + 1}/#{total_pdb}): complete whbonds already!"
              next
            end

            whbonds = Array.new
            whbonds_bio = BIPA::HBPlus.new(IO.readlines(hbplus_file).join).whbonds

            whbonds_bio.each do |whbond|
              aa_atom = structure.models[0].chains.find_by_chain_code(whbond.aa_atom.chain_code).residues.find_by_residue_code_and_icode(whbond.aa_atom.residue_code, whbond.aa_atom.insertion_code).atoms.find_by_atom_name(whbond.aa_atom.atom_name)
              na_atom = structure.models[0].chains.find_by_chain_code(whbond.na_atom.chain_code).residues.find_by_residue_code_and_icode(whbond.na_atom.residue_code, whbond.na_atom.insertion_code).atoms.find_by_atom_name(whbond.na_atom.atom_name)
              water_atom = structure.models[0].chains.find_by_chain_code(whbond.water_atom.chain_code).residues.find_by_residue_code_and_icode(whbond.water_atom.residue_code, whbond.water_atom.insertion_code).atoms.find_by_atom_name(whbond.water_atom.atom_name)

              if aa_atom && na_atom && water_atom
                whbonds << [aa_atom[:id], na_atom[:id], water_atom[:id]]
              end
            end

            columns = [:atom_id, :whbonding_atom_id, :water_atom_id]
            Whbond.import(columns, whbonds, :on_duplicate_key_update => [:water_atom_id])

            if whbonds.size > 0
              structure.has_complete_whbonds = true
              structure.save!
            end

            puts "Importing WHBONDS in #{pdb_code} (#{i + 1}/#{total_pdb}): done"

            ActiveRecord::Base.remove_connection
          end # fork_manager.fork
        end # pdb_codes.each_with_index
        ActiveRecord::Base.establish_connection(config)
      end # fork_manager.manage
    end


    desc "Import SCOP datasets"
    task :scop => [:environment] do

      hierarchy_file    = Dir[File.join(BIPA_ENV[:SCOP_DIR], '*hie*scop*')][0]
      description_file  = Dir[File.join(BIPA_ENV[:SCOP_DIR], '*des*scop*')][0]

      # Create a hash for description of scop entries, 
      # and set a description for 'root' scop entry with sunid, '0'
      descriptions      = Hash.new
      descriptions['0'] = {
        :sunid        => '0',
        :stype        => 'root',
        :sccs         => 'root',
        :sid          => 'root',
        :description  => 'root',
      }

      # # dir.des.scop.txt
      # 46456   cl      a       -       All alpha proteins [46456]
      # 46457   cf      a.1     -       Globin-like
      # 46458   sf      a.1.1   -       Globin-like
      # 46459   fa      a.1.1.1 -       Truncated hemoglobin
      # 46460   dm      a.1.1.1 -       Protozoan/bacterial hemoglobin
      # 46461   sp      a.1.1.1 -       Ciliate (Paramecium caudatum) [TaxId: 5885]
      # 14982   px      a.1.1.1 d1dlwa_ 1dlw A:
      # 100068  px      a.1.1.1 d1uvya_ 1uvy A:
      IO.foreach(description_file) do |line|
        next if line =~ /^#/ || line =~ /^\s*$/ # Skip empty lines
          sunid, stype, sccs, sid, description = line.chomp.split(/\t/)
        sccs = '-' if sccs =~ /unassigned/
          sid = '-' if sid =~ /unassigned/
          descriptions[sunid] = {
          :sunid => sunid,
          :stype => stype,
          :sccs => sccs,
          :sid => sid,
          :description => description
        }
      end

      # # dir.hie.scop.txt
      # 46460   46459   46461,46462,81667,63437,88965,116748
      # 14982   46461   -
      IO.readlines(hierarchy_file).each_with_index do |line, i|
        next if line =~ /^#/ || line =~ /^\s*$/
          self_sunid, parent_sunid, children_sunids = line.chomp.split(/\t/)

        current_scop = Scop.factory_create!(descriptions[self_sunid])
        unless self_sunid.to_i == 0
          parent_scop = Scop.find_by_sunid(parent_sunid)
          current_scop.move_to_child_of parent_scop
        end
      end
    end # task :scop


    desc "Import Domain Interfaces"
    task :domain_interfaces => [:environment] do

      pdb_codes = Structure.find(:all).map(&:pdb_code)
      fmanager  = ForkManager.new(BIPA_ENV[:MAX_FORK])

      fmanager.manage do

        config = ActiveRecord::Base.remove_connection

        pdb_codes.each_with_index do |pdb_code, i|

          fmanager.fork do

            ActiveRecord::Base.establish_connection(config)
            structure = Structure.find_by_pdb_code(pdb_code)

            structure.domains.each do |domain|

              registered = false

              dna_binding_residues = domain.residues.select(&:binding_dna?)

              if dna_binding_residues.length > 0
                (domain.dna_interfaces.create).residues << dna_binding_residues
                registered = true
                puts "#{domain.sid} has an dna interface"
              end

              rna_binding_residues = domain.residues.select(&:binding_rna?)

              if rna_binding_residues.length > 0
                (domain.rna_interfaces).create.residues << rna_binding_residues
                registered = true
                puts "#{domain.sid} has an rna interface"
              end

              if registered
                domain.registered = true
                domain.save!
                domain.ancestors.each do |a|
                  a.registered = true
                  a.save!
                end
              else
                puts "#{domain.sid} has no interface"
              end
            end # structure.domains.each

            puts "Populating 'interfaces' table from #{pdb_code} (#{i + 1}/#{pdb_codes.size}): done"
            ActiveRecord::Base.remove_connection
          end # fork_manager.fork
        end # pdb_codes.each_with_index

        ActiveRecord::Base.establish_connection(config)
      end # fork_manager.manage
    end


    desc "Import Chain Interfaces"
    task :chain_interfaces => [:environment] do

      structures    = Structure.find_all_by_complete(true)
      pdb_codes     = structures.map { |s| s.pdb_code }
      total_pdb     = structures.size
      fork_manager  = ForkManager.new(BIPA_ENV[:MAX_FORK])

      fork_manager.manage do
        config = ActiveRecord::Base.remove_connection

        pdb_codes.each_with_index do |pdb_code, i|
          fork_manager.fork do
            ActiveRecord::Base.establish_connection(config)
            structure = Structure.find_by_pdb_code(pdb_code)

            structure.chains.each do |chain|
              dna_residues = chain.dna_binding_interface_residues
              rna_residues = chain.rna_binding_interface_residues

              if dna_residues.length > 0
                (chain.dna_interface = ChainDnaInterface.new).residues << dna_residues
                chain.save!
                puts "#{pdb_code}: #{chain.chain_code} has an dna interface"
              end

              if rna_residues.length > 0
                (chain.rna_interface = ChainRnaInterface.new).residues << rna_residues
                chain.save!
                puts "#{pdb_code}: #{chain.chain_code} has an rna interface"
              end

              if dna_residues.length == 0 && rna_residues.length == 0
                puts "#{pdb_code}: #{chain.chain_code} has no interface"
              end
            end
            puts "Importing 'Chain Interfaces' from #{pdb_code} (#{i + 1}/#{total_pdb}): done"
            ActiveRecord::Base.remove_connection
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end
  end


  desc "Import Clusters for each SCOP family"
  task :clusters => [:environment] do

    families = ScopFamily.find_registered(:all)
    families.each_with_index do |family, i|

      family_dir = File.join(BIPA_ENV[:BLASTCLUST_SCOP_FAMILY_DIR], "#{family.sunid}")

      (10..100).step(10) do |id|
        cluster_file = File.join(family_dir, family.sunid.to_s + '.nr' + id.to_s + '.fa')

        IO.readlines(cluster_file).each do |line|
          cluster = "Cluster#{id}".constantize.new

          members = line.split(/\s+/)
          members.each do |member|
            scop_domain = ScopDomain.find_by_sunid(member)
            cluster.scop_domains << scop_domain
          end

          cluster.scop_family = family
          cluster.save!
          puts "Cluster#{id} (#{cluster.id}): created"
        end
      end

      puts "Import clusters for #{family.sunid} : done (#{i+1}/#{families.size})"
    end
  end

end
