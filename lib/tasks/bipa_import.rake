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

            # Filter C-alpha only structures using HBPLUS results
            hbplus_file = File.join(HBPLUS_DIR, "#{pdb_code}.hb2")
            hbonds_bipa = Bipa::Hbplus.new(IO.read(hbplus_file)).hbonds

            if hbonds_bipa.empty?
              $logger.warn("SKIP: #{pdb_code} might be a C-alpha only structure. No HBPLUS results found!")
              next
            end

            # Load NACCESS results for every atom in the structure
            bound_asa_file      = File.join(NACCESS_DIR, "#{pdb_code}_co.asa")
            unbound_aa_asa_file = File.join(NACCESS_DIR, "#{pdb_code}_aa.asa")
            unbound_na_asa_file = File.join(NACCESS_DIR, "#{pdb_code}_na.asa")

            if (!File.exists?(bound_asa_file)       ||
                !File.exists?(unbound_aa_asa_file)  ||
                !File.exists?(unbound_na_asa_file))
              $logger.warn("SKIP: #{pdb_code} might be an improper PDB file. No NACCESS result found!")
              next
            end

            bound_atom_asa      = Bipa::Naccess.new(IO.read(bound_asa_file)).atom_asa
            unbound_aa_atom_asa = Bipa::Naccess.new(IO.read(unbound_aa_asa_file)).atom_asa
            unbound_na_atom_asa = Bipa::Naccess.new(IO.read(unbound_na_asa_file)).atom_asa

            # Load DSSP results for every amino acid residue in the structure
            dssp_file = File.join(DSSP_DIR, "#{pdb_code}.dssp")

            if (!File.exists?(dssp_file))
              $logger.warn("SKIP: #{pdb_code} due to missing DSSP result file")
              next
            end

            dssp_sstruc = Bipa::Dssp.new(IO.readlines(dssp_file).join).sstruc

            # Load ZAP results for every atoms
            ZapAtom     = Struct.new(:index, :serial, :symbol, :radius,
                                     :formal_charge, :partial_charge, :potential)
            aa_zap_file = File.join(ZAP_DIR, "#{pdb_code}_aa.zap")
            na_zap_file = File.join(ZAP_DIR, "#{pdb_code}_na.zap")
            aa_zap_err  = File.join(ZAP_DIR, "#{pdb_code}_aa.err")
            na_zap_err  = File.join(ZAP_DIR, "#{pdb_code}_na.err")

            if (!File.size?(aa_zap_file) || !File.size?(na_zap_file))
              $logger.warn("SKIP: #{pdb_code} due to missing ZAP result")
              next
            end

            if (File.size?(aa_zap_err) || File.size?(na_zap_err))
              $logger.warn("SKIP: #{pdb_code} due to errors in ZAP calculation")
              next
            end

            aa_zap_atoms  = Hash.new
            na_zap_atoms  = Hash.new
            tainted_zap   = false

            IO.foreach(aa_zap_file) do |line|
              elems = line.chomp.split(/\s+/)
              unless elems.size == 7
                tainted_zap = true
                break
              end
              zap = ZapAtom.new(elems[0].to_i,
                                elems[1].to_i,
                                elems[2],
                                elems[3].to_f,
                                elems[4].to_f,
                                elems[5].to_f,
                                elems[6].to_f)
              aa_zap_atoms[zap[:serial]] = zap
            end

            IO.foreach(na_zap_file) do |line|
              elems = line.chomp.split(/\s+/)
              unless elems.size == 7
                tainted_zap = true
                break
              end
              zap = ZapAtom.new(elems[0].to_i,
                                elems[1].to_i,
                                elems[2],
                                elems[3].to_f,
                                elems[4].to_f,
                                elems[5].to_f,
                                elems[6].to_f)
              na_zap_atoms[zap[:serial]] = zap
            end

            if tainted_zap
              $logger.warn("SKIP: #{pdb_code} due to tainted ZAP result")
              next
            end

            # helper methods for params
            def residue_params(chain_id, residue, sstruc = nil)
              {
                :chain_id             => chain_id,
                :residue_code         => residue.residue_id,
                :icode                => (residue.iCode.blank? ? nil : residue.iCode),
                :residue_name         => residue.resName.strip,
                :hydrophobicity       => residue.hydrophobicity,
                :secondary_structure  => sstruc
              }
            end

            def atom_params(residue_id,
                            atom,
                            bound_atom_asa,
                            unbound_aa_atom_asa,
                            unbound_na_atom_asa,
                            aa_zap_atoms,
                            na_zap_atoms)

              bound_asa   = bound_atom_asa[atom.serial]
              unbound_asa = unbound_aa_atom_asa[atom.serial] || unbound_na_atom_asa[atom.serial]
              delta_asa   = unbound_asa - bound_asa if bound_asa && unbound_asa
              zap_atom    = aa_zap_atoms[atom.serial] || na_zap_atoms[atom.serial]

              {
                :residue_id     => residue_id,
                :position_type  => atom.position_type,
                :atom_code      => atom.serial,
                :atom_name      => atom.name.strip,
                :altloc         => atom.altLoc.blank? ? nil : atom.altLoc,
                :x              => atom.x,
                :y              => atom.y,
                :z              => atom.z,
                :occupancy      => atom.occupancy,
                :tempfactor     => atom.tempFactor,
                :element        => atom.element,
                :charge         => atom.charge.blank? ? nil : atom.charge,
                :bound_asa      => bound_asa,
                :unbound_asa    => unbound_asa,
                :delta_asa      => delta_asa,
                :radius         => zap_atom ? zap_atom[:radius]         : nil,
                :formal_charge  => zap_atom ? zap_atom[:formal_charge]  : nil,
                :partial_charge => zap_atom ? zap_atom[:partial_charge] : nil,
                :potential      => zap_atom ? zap_atom[:potential]      : nil
              }
            end

            # Parse molecule and chain information
            # Very dirty... it needs refactoring!
            mol_codes = {}
            molecules = {}

#            mol_id    = nil
#            molecule  = nil
#
#            pdb_bio.record("COMPND")[0].compound.each do |key, value|
#              case
#              when key == "MOL_ID"
#                mol_id = value
#              when key == "MOLECULE"
#                molecule = value
#              when key == "CHAIN"
#                mol_codes[value] = mol_id
#                molecules[value] = molecule
#              end
#            end

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
              :resolution     => pdb_bio.resolution.to_f < EPSILON ? nil : pdb_bio.resolution,
              :deposited_at   => pdb_bio.deposition_date
            )

            model_bio = pdb_bio.models.first

            model = Model.create!(
              :structure_id => structure.id,
              :model_code   => model_bio.serial ? model_bio.serial : 1
            )

            # Create empty atoms array for massive importing Atom AREs
            atoms = Array.new

            model_bio.each do |chain_bio|

              chain_code = chain_bio.chain_id.blank? ? nil : chain_bio.chain_id

              chain_type = if chain_bio.aa?
                             AaChain
                           elsif chain_bio.dna?
                             DnaChain
                           elsif chain_bio.rna?
                             RnaChain
                           elsif chain_bio.hna?
                             HnaChain
                           else
                             HetChain
                           end

              chain = chain_type.create!(
                :model_id   => model.id,
                :chain_code => chain_code,
                :mol_code   => mol_codes[chain_code] ? mol_codes[chain_code] : nil,
                :molecule   => molecules[chain_code] ? molecules[chain_code] : nil
              )


              chain_bio.each_residue do |residue_bio|
                if residue_bio.dna?
                  residue = DnaResidue.create!(residue_params(chain.id, residue_bio))
                elsif residue_bio.rna?
                  residue = RnaResidue.create!(residue_params(chain.id, residue_bio))
                else
                  dssp_hash_key = chain_bio.chain_id + residue_bio.residue_id
                  sstruc        = dssp_sstruc[dssp_hash_key] ? dssp_sstruc[dssp_hash_key] : "L"
                  residue       = AaResidue.create!(residue_params(chain.id, residue_bio, sstruc))
                end

                residue_bio.each do |atom_bio|
                  atoms << Atom.new(atom_params(residue.id,
                                                atom_bio,
                                                bound_atom_asa,
                                                unbound_aa_atom_asa,
                                                unbound_na_atom_asa,
                                                aa_zap_atoms,
                                                na_zap_atoms))
                end
              end

              chain_bio.each_heterogen do |het_residue_bio|
                het_residue = HetResidue.create!(residue_params(chain.id, het_residue_bio))

                het_residue_bio.each do |het_atom_bio|
                  atoms << Atom.new(atom_params(het_residue.id,
                                                het_atom_bio,
                                                bound_atom_asa,
                                                unbound_aa_atom_asa,
                                                unbound_na_atom_asa,
                                                aa_zap_atoms,
                                                na_zap_atoms))
                end
              end
            end

            Atom.import(atoms, :validate => false)
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

      pdb_codes = Structure.find(:all).map(&:pdb_code)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        pdb_codes.each_with_index do |pdb_code, i|

          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)

            structure = Structure.find_by_pdb_code(pdb_code)
            kdtree    = Bipa::Kdtree.new
            contacts  = []

            structure.atoms.each { |a| kdtree.insert(a) }

            aa_atoms = structure.aa_atoms
            na_atoms = structure.na_atoms

            if aa_atoms.size > na_atoms.size
              na_atoms.each do |na_atom|
                neighbor_atoms = kdtree.neighbors(na_atom, MAX_DISTANCE).map(&:point)
                neighbor_atoms.each do |neighbor_atom|
                  if neighbor_atom.aa?
                    dist = na_atom - neighbor_atom
                    contacts << [neighbor_atom.id, na_atom.id, dist]
                  end
                end
              end
            else
              aa_atoms.each do |aa_atom|
                neighbor_atoms = kdtree.neighbors(aa_atom, MAX_DISTANCE).map(&:point)
                neighbor_atoms.each do |neighbor_atom|
                  if neighbor_atom.na?
                    dist = aa_atom - neighbor_atom
                    contacts << [aa_atom.id, neighbor_atom.id, dist]
                  end
                end
              end
            end

            columns = [:atom_id, :contacting_atom_id, :distance]
            Contact.import(columns, contacts)
            structure.save!
            ActiveRecord::Base.remove_connection

            $logger.info("Importing 'contacts' in #{pdb_code} (#{i + 1}/#{pdb_codes.size}): done")
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


    desc "Import Hydrogen Bonds"
    task :hbonds => [:environment] do

      pdb_codes = Structure.find(:all).map(&:pdb_code)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        pdb_codes.each_with_index do |pdb_code, i|

          fmanager.fork do
            hbplus_file = File.join(HBPLUS_DIR, "#{pdb_code.downcase}.hb2")

            raise "Cannot find #{hbplus_file}, this cannot be happend!" if !File.exist? hbplus_file

            ActiveRecord::Base.establish_connection(config)

            structure   = Structure.find_by_pdb_code(pdb_code)
            hbonds_bipa = Bipa::Hbplus.new(IO.read(hbplus_file)).hbonds
            hbonds      = Array.new

            hbonds_bipa.each do |hbond|
              if ((hbond.donor.aa? && hbond.acceptor.na?) || (hbond.donor.na? && hbond.acceptor.aa?))
                begin
                  donor_atom    =
                    structure.
                    models.first.
                    chains.find_by_chain_code(hbond.donor.chain_code).
                    residues.find_by_residue_code_and_icode(hbond.donor.residue_code, hbond.donor.insertion_code).
                    atoms.find_by_atom_name(hbond.donor.atom_name)

                  acceptor_atom =
                    structure.
                    models.first.
                    chains.find_by_chain_code(hbond.acceptor.chain_code).
                    residues.find_by_residue_code_and_icode(hbond.acceptor.residue_code, hbond.acceptor.insertion_code).
                    atoms.find_by_atom_name(hbond.acceptor.atom_name)
                rescue
                  $logger.warn("Cannot find #{pdb_code}: #{hbond.donor} <=> #{hbond.acceptor}")
                  next
                else
                  if donor_atom && acceptor_atom
                    hbonds << [
                      donor_atom.id,
                      acceptor_atom.id,
                      hbond.da_distance,
                      hbond.category,
                      hbond.gap,
                      hbond.ca_distance,
                      hbond.dha_angle,
                      hbond.ha_distance,
                      hbond.haaa_angle,
                      hbond.daaa_angle
                    ]
                  end
                end
              end
            end

            columns = [
              :donor_id,
              :acceptor_id,
              :da_distance,
              :category,
              :gap,
              :ca_distance,
              :dha_angle,
              :ha_distance,
              :haaa_angle,
              :daaa_angle
            ]

            Hbond.import(columns, hbonds,
                         :on_duplicate_update => [
                           :donor_id,
                           :acceptor_id,
                           :da_distance,
                           :category,
                           :gap,
                           :ca_distance,
                           :dha_angle,
                           :ha_distance,
                           :haaa_angle,
                           :daaa_angle])

            ActiveRecord::Base.remove_connection
            $logger.info("Importing 'hbonds' for #{pdb_code} (#{i + 1}/#{pdb_codes.size}): done")
          end # fmanager.fork
        end # pdb_codes.each_with_index
        ActiveRecord::Base.establish_connection(config)
      end # fmanager.manage
    end


    desc "Import Water-mediated hydrogen bonds"
    task :whbonds => [:environment] do

      pdb_codes = Structure.find(:all).map(&:pdb_code)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        pdb_codes.each_with_index do |pdb_code, i|

          fmanager.fork do
            hbplus_file = File.join(HBPLUS_DIR, "#{pdb_code.downcase}.hb2")

            raise "Cannot find #{hbplus_file}, this cannot be happend!" if !File.exist? hbplus_file

            ActiveRecord::Base.establish_connection(config)

            structure   = Structure.find_by_pdb_code(pdb_code)
            whbonds_bio = Bipa::Hbplus.new(IO.read(hbplus_file)).whbonds
            whbonds     = Array.new

            whbonds_bio.each do |whbond|
              aa_atom = structure.
                models.first.
                chains.find_by_chain_code(whbond.aa_atom.chain_code).
                residues.find_by_residue_code_and_icode(whbond.aa_atom.residue_code, whbond.aa_atom.insertion_code).
                atoms.find_by_atom_name(whbond.aa_atom.atom_name)

              na_atom = structure.
                models.first.
                chains.find_by_chain_code(whbond.na_atom.chain_code).
                residues.find_by_residue_code_and_icode(whbond.na_atom.residue_code, whbond.na_atom.insertion_code).
                atoms.find_by_atom_name(whbond.na_atom.atom_name)

              water_atom =  structure.
                models.first.
                chains.find_by_chain_code(whbond.water_atom.chain_code).
                residues.find_by_residue_code_and_icode(whbond.water_atom.residue_code, whbond.water_atom.insertion_code).
                atoms.find_by_atom_name(whbond.water_atom.atom_name)

              if aa_atom && na_atom && water_atom
                whbonds << [aa_atom.id, na_atom.id, water_atom.id]
              end
            end

            columns = [:atom_id, :whbonding_atom_id, :water_atom_id]
            Whbond.import(columns, whbonds)

            ActiveRecord::Base.remove_connection

            $logger.info("Importing 'whbonds' for #{pdb_code} (#{i + 1}/#{pdb_codes.size}): done")
          end # fmanager.fork
        end # pdb_codes.each_with_index
        ActiveRecord::Base.establish_connection(config)
      end # fmanager.manage
    end


    desc "Import SCOP datasets"
    task :scop => [:environment] do

      hie_file = Dir[File.join(SCOP_DIR, '*hie*scop*')][0]
      des_file = Dir[File.join(SCOP_DIR, '*des*scop*')][0]

      # Create a hash for description of scop entries,
      # and set a description for 'root' scop entry with sunid, '0'
      scop_des      = Hash.new
      scop_des['0'] = {
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
      IO.foreach(des_file) do |line|
        next if line =~ /^#/ || line.blank?
        sunid, stype, sccs, sid, description = line.chomp.split(/\t/)
        sccs  = nil if sccs =~ /unassigned/
        sid   = nil if sid  =~ /unassigned/
        scop_des[sunid] = {
          :sunid        => sunid,
          :stype        => stype,
          :sccs         => sccs,
          :sid          => sid,
          :description  => description
        }
      end

      # # dir.hie.scop.txt
      # 46460   46459   46461,46462,81667,63437,88965,116748
      # 14982   46461   -
      IO.readlines(hie_file).each_with_index do |line, i|
        next if line =~ /^#/ || line.blank?

        self_sunid, parent_sunid, children_sunids = line.chomp.split(/\t/)
        current_scop = Scop.factory_create!(scop_des[self_sunid])

        unless self_sunid.to_i == 0
          parent_scop = Scop.find_by_sunid(parent_sunid)
          current_scop.move_to_child_of(parent_scop)
        end
        #$logger.info("Importing SCOP sunid, #{self_sunid}: (#{i + 1}) done")
      end
    end # task :scops


    desc "Import Domain Interfaces"
    task :domain_interfaces => [:environment] do

      pdb_codes = Structure.find(:all).map(&:pdb_code)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        pdb_codes.each_with_index do |pdb_code, i|

          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)

            domains = ScopDomain.find_all_by_pdb_code(pdb_code)

            domains.each do |domain|
              iface_found = false

              %w(dna rna).each do |na|
                if domain.send("#{na}_interfaces").size > 0
                  $logger.info("#{domain.sid} has a #{na} interface already detected")
                  iface_found = true
                  next
                else
                  $logger.info("#{domain.sid} has no #{na} interface")
                end

                if domain.send("#{na}_binding_interface_residues").size > 0
                  iface = "Domain#{na.camelize}Interface".constantize.new
                  iface.domain = domain
                  iface.residues << domain.send("#{na}_binding_interface_residues")
                  iface.save!
                  iface_found = true
                  $logger.info("#{domain.sid} has a #{na} interface")
                end
              end

              if iface_found == true
                domain.registered = true
                domain.save!
                domain.ancestors.each do |a|
                  a.registered = true
                  a.save!
                end
              end
            end # domains.each

            $logger.info("Extracting domain interfaces from #{pdb_code} (#{i + 1}/#{pdb_codes.size}): done")
            ActiveRecord::Base.remove_connection
          end # fmanager.fork
        end # pdb_codes.each_with_index
        ActiveRecord::Base.establish_connection(config)
      end # fmanager.manage
    end


    desc "Import Chain Interfaces"
    task :chain_interfaces => [:environment] do

      pdb_codes = Structure.find(:all).map(&:pdb_code)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        pdb_codes.each_with_index do |pdb_code, i|

          fmanager.fork do
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

            puts "Importing 'Chain Interfaces' from #{pdb_code} (#{i + 1}/#{pdb_codes.size}): done"
            ActiveRecord::Base.remove_connection
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


    desc "Import Subfamilies for each SCOP family"
    task :subfamilies => [:environment] do

      families = ScopFamily.registered.find(:all)

      families.each_with_index do |family, i|
        family_dir = File.join(BLASTCLUST_DIR, "#{family.sunid}")

        (10..100).step(10) do |si|
          subfamily_file = File.join(family_dir, family.sunid.to_s + '.nr' + si.to_s + '.fa')

          IO.readlines(subfamily_file).each do |line|
            subfamily = "Rep#{si}Subfamily".constantize.new

            members = line.split(/\s+/)
            members.each do |member|
              domain = ScopDomain.find_by_sunid(member)
              subfamily.domains << domain
            end

            subfamily.family = family
            subfamily.save!

            $logger.info("Rep#{si}Subfamily} (#{subfamily.id}): created")
          end
        end
        $logger.info("Importing subfamilies for #{family.sunid} : done (#{i + 1}/#{families.size})")
      end
    end


    desc "Import Full & Representative Alignments for each SCOP Family"
    task :full_alignments => [:environment] do

      sunids    = ScopFamily.registered.find(:all).map(&:sunid)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        sunids.each_with_index do |sunid, i|

          fmanager.fork do

            ActiveRecord::Base.establish_connection(config)

            family    = ScopFamily.find_by_sunid(sunid)
            fam_dir   = File.join(FAMILY_DIR, "full", sunid.to_s)
            ali_file  = File.join(fam_dir, "baton.ali")

            unless File.exists?(ali_file)
              $logger.warn("Cannot find #{ali_file}")
              next
            end

            alignment = family.send("build_full_alignment")
            flat_file = Bio::FlatFile.auto(ali_file)

            flat_file.each_entry do |entry|
              next unless entry.seq_type == "P1"

              domain          = ScopDomain.find_by_sunid(entry.entry_id)
              db_residues     = domain.residues
              ff_residues     = entry.data.split("")
              sequence        = alignment.sequences.build
              sequence.domain = domain

              pos = 0

              ff_residues.each_with_index do |res, fi|
                column = sequence.columns.build

                if (res == "-")
                  column.residue_name = res
                  column.position     = fi + 1
                  column.save!
                else
                  if (db_residues[pos].one_letter_code == res)
                    column.residue      = db_residues[pos]
                    column.residue_name = res
                    column.position     = fi + 1
                    column.save!
                    pos += 1
                  else
                    raise "Mismatch at #{pos}, between #{res} and #{db_residues[pos].one_letter_code} of #{domain.sid}"
                  end
                end
              end # ff_residues.each_with_index
              sequence.save!
            end # flat_file.each_entry
            alignment.save!
            ActiveRecord::Base.remove_connection
            $logger.info("Importing full alignments of SCOP family, #{sunid}: done (#{i + 1}/#{sunids.size})")
          end # fmanger.fork
        end # sunids.each
        ActiveRecord::Base.establish_connection(config)
      end # fmanager.manage
    end # task :full_alignments


    desc "Import representative alignments for each SCOP Family"
    task :rep_alignments => [:environment] do

      sunids    = ScopFamily.registered.find(:all).map(&:sunid)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        sunids.each_with_index do |sunid, i|

          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)

            family = ScopFamily.find_by_sunid(sunid)

            (10..100).step(10) do |si|
              family_dir  = File.join(FAMILY_DIR, "rep#{si}", "#{family.sunid}")
              ali_file    = File.join(family_dir, "baton.ali")

              unless File.exists?(ali_file)
                $logger.warn("Cannot find #{ali_file}")
                next
              end

              alignment = family.send("build_rep#{si}_alignment")
              flat_file = Bio::FlatFile.auto(ali_file)

              flat_file.each_entry do |entry|
                next unless entry.seq_type == "P1"

                domain          = ScopDomain.find_by_sunid(entry.entry_id)
                db_residues     = domain.residues
                ff_residues     = entry.data.split("")
                sequence        = alignment.sequences.build
                sequence.domain = domain

                pos = 0

                ff_residues.each_with_index do |res, fi|
                  column = sequence.columns.build

                  if (res == "-")
                    column.residue_name = res
                    column.position     = fi + 1
                    column.save!
                  else
                    if (db_residues[pos].one_letter_code == res)
                      column.residue      = db_residues[pos]
                      column.residue_name = res
                      column.position     = fi + 1
                      column.save!
                      pos += 1
                    else
                      raise "Mismatch at #{pos}, between #{res} and #{db_residues[pos].one_letter_code} of #{domain.sid}"
                    end
                  end
                end # ff_residues.each_with_index
                sequence.save!
              end # flat_file.each_entry
              alignment.save!
            end # (10..100).step(10)
            ActiveRecord::Base.remove_connection
            $logger.info("Importing representative alignments of SCOP family, #{sunid}: done (#{i + 1}/#{sunids.size})")
          end # fmanger.fork
        end # sunids.each
        ActiveRecord::Base.establish_connection(config)
      end # fmanager.manage
    end # task :alignments


    desc "Import subfamily alignments for each SCOP Family"
    task :sub_alignments => [:environment] do

      sunids    = ScopFamily.registered.find(:all).map(&:sunid)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        sunids.each_with_index do |sunid, i|

          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)

            (10..100).step(10) do |si|
              rep_dir     = File.join(FAMILY_DIR, "sub", sunid.to_s, "rep#{si}")
              subfam_ids  = Dir[rep_dir + "/*"].map { |d| d.match(/(\d+)$/)[1] }

              subfam_ids.each do |subfam_id|
                ali_file = File.join(rep_dir, subfam_id, "baton.ali")

                unless File.exists?(ali_file)
                  $logger.warn("Cannot find #{ali_file}")
                  next
                end

                alignment = Subfamily.find(subfam_id).build_alignment
                flat_file = Bio::FlatFile.auto(ali_file)

                flat_file.each_entry do |entry|
                  next unless entry.seq_type == "P1"

                  domain          = ScopDomain.find_by_sunid(entry.entry_id)
                  db_residues     = domain.residues
                  ff_residues     = entry.data.split("")
                  sequence        = alignment.sequences.build
                  sequence.domain = domain

                  pos = 0

                  ff_residues.each_with_index do |res, fi|
                    column = sequence.columns.build

                    if (res == "-")
                      column.residue_name = res
                      column.position     = fi + 1
                      column.save!
                    else
                      if (db_residues[pos].one_letter_code == res)
                        column.residue      = db_residues[pos]
                        column.residue_name = res
                        column.position     = fi + 1
                        column.save!
                        pos += 1
                      else
                        raise "Mismatch at #{pos}, between #{res} and #{db_residues[pos].one_letter_code} of #{domain.sid}"
                      end
                    end
                  end # ff_residues.each_with_index
                  sequence.save!
                end # flat_file.each_entry
                alignment.save!
              end # subfam_ids.each
            end # (10..100).step(10)
            ActiveRecord::Base.remove_connection
            $logger.info("Importing subfamily alignments of SCOP family, #{sunid}: done (#{i + 1}/#{sunids.size})")
          end # fmanager.fork
        end # sunids.each
        ActiveRecord::Base.establish_connection(config)
      end # fmanager.manage
    end # task :sub_alignments

  end
end
