namespace :bipa do
  namespace :import do

  require "logger"

  $logger = Logger.new(STDOUT)


  desc "Import protein-nucleic acid complex PDB files to BIPA tables"
  task :pdb => [:environment] do

    pdb_files = Dir[File.join(PDB_DIR, "*.pdb")].sort
    fmanager  = ForkManager.new(MAX_FORK)

    fmanager.manage do

      config = ActiveRecord::Base.remove_connection

      pdb_files.each_with_index do |pdb_file, i|

        fmanager.fork do

          ActiveRecord::Base.establish_connection(config)

          pdb_code  = File.basename(pdb_file, ".pdb")
          pdb_bio   = Bio::PDB.new(IO.read(pdb_file))

          # Load NACCESS results for every atom in the structure
          bound_asa_file      = File.join(NACCESS_DIR, "#{pdb_code}.asa")
          unbound_aa_asa_file = File.join(NACCESS_DIR, "#{pdb_code}_aa.asa")
          unbound_na_asa_file = File.join(NACCESS_DIR, "#{pdb_code}_na.asa")

          bound_atom_asa      = Bipa::Naccess.new(IO.readlines(bound_asa_file).join).atom_asa
          unbound_aa_atom_asa = Bipa::Naccess.new(IO.readlines(unbound_aa_asa_file).join).atom_asa
          unbound_na_atom_asa = Bipa::Naccess.new(IO.readlines(unbound_na_asa_file).join).atom_asa

          # Load DSSP results for every amino acid residue in the structure
          dssp_file   = File.join(DSSP_DIR, "#{pdb_code}.dssp")
          dssp_sstruc = Bipa::Dssp.new(IO.readlines(dssp_file).join).sstruc

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

          structure = Bipa::Structure.create!(
            :pdb_code       => pdb_bio.accession,
            :classification => pdb_bio.classification,
            :title          => pdb_bio.definition,
            :exp_method     => pdb_bio.exp_method,
            :resolution     => pdb_bio.resolution.to_f < 0.0000001 ? nil : pdb_bio.resolution,
            :deposited_at   => pdb_bio.deposition_date
          )

          model_bio = pdb_bio.models[0]

          model = Bipa::Model.create!(
            :structure_id => structure.id,
            :model_code   => model_bio.serial ? model_bio.serial : 1
          )

          # Create empty atoms array for massive importing Atom AREs
          atoms = Array.new

          model_bio.each do |chain_bio|

            chain_code = chain_bio.chain_id.empty? ? '-' : chain_bio.chain_id

            chain_type = if chain_bio.aa?
                           Bipa::AaChain
                         elsif chain_bio.dna?
                           Bipa::DnaChain
                         elsif chain_bio.rna?
                           Bipa::RnaChain
                         elsif chain_bio.hna?
                           Bipa::HnaChain
                         else
                           Bipa::HetChain
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

              if residue_bio.dna?
                residue = Bipa::DnaResidue.create!(residue_params(chain.id, residue_bio))
              elsif residue_bio.rna?
                residue = Bipa::RnaResidue.create!(residue_params(chain.id, residue_bio))
              else
                dssp_hash_key = chain_bio.chain_id + residue_bio.residue_id
                # In some cases, there are no 'dssp_hash_key', you should check!
                sstruc        = dssp_sstruc[dssp_hash_key] ? dssp_sstruc[dssp_hash_key] : "L"
                residue       = Bipa::AaResidue.create!(residue_params(chain.id, residue_bio, sstruc))
              end

              residue_bio.each do |atom_bio|

                atoms << Bipa::Atom.new(
                  atom_params(
                    residue.id,
                    atom_bio,
                    bound_atom_asa[atom_bio.serial],
                    unbound_aa_atom_asa[atom_bio.serial] || unbound_na_atom_asa[atom_bio.serial])
                )
              end
            end

            chain_bio.each_heterogen do |het_residue_bio|

              het_residue = Bipa::HetResidue.create!(residue_params(chain.id, het_residue_bio))

              het_residue_bio.each do |het_atom_bio|
                atoms << Bipa::Atom.new(atom_params(het_residue.id, het_atom_bio))
              end
            end
          end

          Bipa::Atom.import(atoms, :validate => false)

          structure.save!

          $logger.info("Importing #{pdb_file}: done (#{i + 1}/#{pdb_files.size})")
          ActiveRecord::Base.remove_connection
        end
      end
      ActiveRecord::Base.establish_connection(config)
    end
  end # task :pdb


  desc "Import van der Waals Contacts"
  task :contacts => [:environment] do

    pdb_codes = Bipa::Structure.find(:all).map(&:pdb_code)
    fmanager  = ForkManager.new(MAX_FORK)

    fmanager.manage do

      config = ActiveRecord::Base.remove_connection

      pdb_codes.each_with_index do |pdb_code, i|

        fmanager.fork do

          ActiveRecord::Base.establish_connection(config)

          structure = Bipa::Structure.find_by_pdb_code(pdb_code)
          kdtree    = Bipa::Kdtree.new
          contacts  = Array.new

          structure.atoms.each { |a| kdtree.insert(a) }

          structure.na_atoms.each do |na_atom|
            neighbor_atoms = kdtree.neighbors(na_atom, MAX_DISTANCE).map(&:point)
            neighbor_atoms.each do |neighbor_atom|
              if neighbor_atom.aa?
                dist = na_atom - neighbor_atom
                contacts << [neighbor_atom.id, na_atom.id, dist]
              end
            end
          end

          columns = [:atom_id, :contacting_atom_id, :distance]
          Bipa::Contact.import(columns, contacts)

          structure.save!
          $logger.info("Importing CONTACTS in #{pdb_code} (#{i + 1}/#{pdb_codes.size}): done")

          ActiveRecord::Base.remove_connection
        end
      end

      ActiveRecord::Base.establish_connection(config)
    end
  end


  desc "Import Hydrogen Bonds"
  task :hbonds => [:environment] do

    pdb_codes = Bipa::Structure.find(:all).map(&:pdb_code)
    fmanager  = ForkManager.new(MAX_FORK)

    fmanager.manage do

      config = ActiveRecord::Base.remove_connection

      pdb_codes.each_with_index do |pdb_code, i|

        fmanager.fork do

          hbplus_file = File.join(HBPLUS_DIR, "#{pdb_code.downcase}.hb2")
          unless File.exist?(hbplus_file)
            puts "Skip #{pdb_code} (#{i + 1}/#{pdb_codes.size}): #{hbplus_file} doesn't exist!"
            next
          end

          ActiveRecord::Base.establish_connection(config)

          structure   = Bipa::Structure.find_by_pdb_code(pdb_code)
          hbonds      = Array.new
          hbonds_bipa = Bipa::Hbplus.new(IO.readlines(hbplus_file).join).hbonds

          hbonds_bipa.each do |hbond|
            if ((hbond.donor.aa? && hbond.acceptor.na?) || (hbond.donor.na? && hbond.acceptor.aa?))
              begin
                donor_atom    = structure.
                                models.first.
                                chains.find_by_chain_code(hbond.donor.chain_code).
                                residues.find_by_residue_code_and_icode(hbond.donor.residue_code, hbond.donor.insertion_code).
                                atoms.find_by_atom_name(hbond.donor.atom_name)

                acceptor_atom = structure.
                                models.first.
                                chains.find_by_chain_code(hbond.acceptor.chain_code).
                                residues.find_by_residue_code_and_icode(hbond.acceptor.residue_code, hbond.acceptor.insertion_code).
                                atoms.find_by_atom_name(hbond.acceptor.atom_name)
              rescue
                puts "Cannot find #{pdb_code}: #{hbond.donor} <=> #{hbond.acceptor}!"
                next
              else
                if donor_atom && acceptor_atom
                  hbonds << [
                    donor_atom.id, acceptor_atom.id, hbond.da_distance,
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

          Bipa::Hbond.import(columns, hbonds)

          $logger.info("Importing HBONDS in #{pdb_code} (#{i + 1}/#{pdb_codes.size}): done")

          ActiveRecord::Base.remove_connection
        end # fmanager.fork
      end # pdb_codes.each_with_index
      ActiveRecord::Base.establish_connection(config)
    end # fmanager.manage
  end


  desc "Import Water-mediated hydrogen bonds"
  task :whbonds => [:environment] do

    pdb_codes = Bipa::Structure.find(:all).map(&:pdb_code)
    fmanager  = ForkManager.new(MAX_FORK)

    fmanager.manage do

      config = ActiveRecord::Base.remove_connection

      pdb_codes.each_with_index do |pdb_code, i|

        fmanager.fork do

          hbplus_file = File.join(HBPLUS_DIR, "#{pdb_code.downcase}.hb2")
          unless File.exist?(hbplus_file)
            puts "Skip #{pdb_code} (#{i + 1}/#{pdb_codes.size}): #{hbplus_file} doesn't exist!"
            next
          end

          ActiveRecord::Base.establish_connection(config)

          structure   = Structure.find_by_pdb_code(pdb_code)
          whbonds     = Array.new
          whbonds_bio = Bipa::Hbplus.new(IO.readlines(hbplus_file).join).whbonds

          whbonds_bio.each do |whbond|
            aa_atom = structure.models[0].chains.find_by_chain_code(whbond.aa_atom.chain_code).residues.find_by_residue_code_and_icode(whbond.aa_atom.residue_code, whbond.aa_atom.insertion_code).atoms.find_by_atom_name(whbond.aa_atom.atom_name)
            na_atom = structure.models[0].chains.find_by_chain_code(whbond.na_atom.chain_code).residues.find_by_residue_code_and_icode(whbond.na_atom.residue_code, whbond.na_atom.insertion_code).atoms.find_by_atom_name(whbond.na_atom.atom_name)
            water_atom = structure.models[0].chains.find_by_chain_code(whbond.water_atom.chain_code).residues.find_by_residue_code_and_icode(whbond.water_atom.residue_code, whbond.water_atom.insertion_code).atoms.find_by_atom_name(whbond.water_atom.atom_name)

            if aa_atom && na_atom && water_atom
              whbonds << [aa_atom[:id], na_atom[:id], water_atom[:id]]
            end
          end

          columns = [:atom_id, :whbonding_atom_id, :water_atom_id]
          Bipa::Whbond.import(columns, whbonds, :on_duplicate_key_update => [:water_atom_id])

          if whbonds.size > 0
            structure.has_complete_whbonds = true
            structure.save!
          end

          puts "Importing WHBONDS in #{pdb_code} (#{i + 1}/#{pdb_codes.size}): done"

          ActiveRecord::Base.remove_connection
        end # fork_manager.fork
      end # pdb_codes.each_with_index
      ActiveRecord::Base.establish_connection(config)
    end # fork_manager.manage
  end


  desc "Import SCOP datasets"
  task :scop => [:environment] do

    hierarchy_file    = Dir[File.join(SCOP_DIR, '*hie*scop*')][0]
    description_file  = Dir[File.join(SCOP_DIR, '*des*scop*')][0]

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
      sccs  = '-' if sccs =~ /unassigned/
        sid   = '-' if sid  =~ /unassigned/
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
      current_scop = Bipa::Scop.factory_create!(descriptions[self_sunid])

      unless self_sunid.to_i == 0
        parent_scop = Bipa::Scop.find_by_sunid(parent_sunid)
        current_scop.move_to_child_of parent_scop
      end
      $logger.info("Importing SCOP sunid, #{self_sunid}: (#{i + 1}) done")
    end
  end # task :scop


  desc "Import Domain Interfaces"
  task :domain_interfaces => [:environment] do

    pdb_codes = Bipa::Structure.find(:all).map(&:pdb_code)
    fmanager  = ForkManager.new(MAX_FORK)

    fmanager.manage do

      config = ActiveRecord::Base.remove_connection

      pdb_codes.each_with_index do |pdb_code, i|

        fmanager.fork do

          ActiveRecord::Base.establish_connection(config)
          structure = Bipa::Structure.find_by_pdb_code(pdb_code)

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

          $logger.info("Populating 'interfaces' table from #{pdb_code} (#{i + 1}/#{pdb_codes.size}): done")
          ActiveRecord::Base.remove_connection
        end # fork_manager.fork
      end # pdb_codes.each_with_index

      ActiveRecord::Base.establish_connection(config)
    end # fork_manager.manage
  end


  desc "Import Chain Interfaces"
  task :chain_interfaces => [:environment] do

    pdb_codes = Bipa::Structure.find(:all).map(&:pdb_code)
    fmanager  = ForkManager.new(MAX_FORK)

    fmanager.manage do

      config = ActiveRecord::Base.remove_connection

      pdb_codes.each_with_index do |pdb_code, i|

        fmanager.fork do

          ActiveRecord::Base.establish_connection(config)

          structure = Bipa::Structure.find_by_pdb_code(pdb_code)

          structure.chains.each do |chain|

            dna_residues = chain.dna_binding_interface_residues
            rna_residues = chain.rna_binding_interface_residues

            if dna_residues.length > 0
              (chain.dna_interface = Bipa::ChainDnaInterface.new).residues << dna_residues
              chain.save!
              puts "#{pdb_code}: #{chain.chain_code} has an dna interface"
            end

            if rna_residues.length > 0
              (chain.rna_interface = Bipa::ChainRnaInterface.new).residues << rna_residues
              chain.save!
              puts "#{pdb_code}: #{chain.chain_code} has an rna interface"
            end

            if dna_residues.length == 0 && rna_residues.length == 0
              puts "#{pdb_code}: #{chain.chain_code} has no interface"
            end
          end

          puts "Importing 'Chain Interfaces' from #{pdb_code} (#{i + 1}/#{pdb_codes.size}): done"
          ActiveRecord::Base.remove_connection
        end
      end
      ActiveRecord::Base.establish_connection(config)
    end
  end
  end


  desc "Import Clusters for each SCOP family"
  task :clusters => [:environment] do

    families = Bipa::ScopFamily.find_registered(:all)

    families.each_with_index do |family, i|

      family_dir = File.join(BLASTCLUST_DIR, "#{family.sunid}")

      (10..100).step(10) do |si|

        cluster_file = File.join(family_dir, family.sunid.to_s + '.nr' + si.to_s + '.fa')

        IO.readlines(cluster_file).each do |line|

          cluster = "Bipa::Cluster#{si}".constantize.new

          members = line.split(/\s+/)
          members.each do |member|
            scop_domain = Bipa::ScopDomain.find_by_sunid(member)
            cluster.scop_domains << scop_domain
          end

          cluster.scop_family = family
          cluster.save!

          $logger.info("Cluster#{si} (#{cluster.id}): created")
        end
      end

      $logger.info("Import clusters for #{family.sunid} : done (#{i + 1}/#{families.size})")
    end
  end

end
