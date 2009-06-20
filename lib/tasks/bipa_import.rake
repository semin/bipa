namespace :bipa do
  namespace :import do

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
        $logger.info "Importing SCOP, #{self_sunid}: done (#{i + 1})"
      end
    end # task :scop


    desc "Import protein-nucleic acid complex PDB files to BIPA tables"
    task :pdb => [:environment] do

      # helper methods for Residue and Atom params
      def residue_params(bio_residue)
        {
          :chain_id             => bio_residue.chain.id,
          :residue_code         => bio_residue.residue_id,
          :icode                => (bio_residue.iCode.blank? ? nil : bio_residue.iCode),
          :residue_name         => bio_residue.resName.strip,
        }
      end

      def atom_params(bio_atom)
        {
          :residue_id => bio_atom.residue.id,
          :moiety     => bio_atom.moiety,
          :atom_code  => bio_atom.serial,
          :atom_name  => bio_atom.name.strip,
          :altloc     => (bio_atom.altLoc.blank? ? nil : bio_atom.altLoc),
          :x          => bio_atom.x,
          :y          => bio_atom.y,
          :z          => bio_atom.z,
          :occupancy  => bio_atom.occupancy,
          :tempfactor => bio_atom.tempFactor,
          :element    => bio_atom.element,
          :charge     => (bio_atom.charge.blank? ? nil : bio_atom.charge),
        }
      end

      pdb_files = FileList[PDB_DIR+"/*.pdb"].sort
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        pdb_files.each_with_index do |pdb_file, i|

          fmanager.fork do
            pdb_code  = File.basename(pdb_file, ".pdb")
            bio_pdb   = Bio::PDB.new(IO.read(pdb_file))

            # Parse molecule and chain information
            # Very dirty... it needs refactoring!
            mol_codes = {}
            molecules = {}

            compnd = bio_pdb.record('COMPND')[0].original_data.map { |s|
              s.gsub(/^COMPND\s+\d*\s+/,'').gsub(/\s*$/,'')
            }.join + ";"

            compnd.scan(/MOL_ID:\s+(\d+);MOLECULE:\s+(.*?);CHAIN:\s+(.*?);/) do |mol_id, molecule, chain_codes|
              chain_codes.split(/,/).each do |chain_code|
                chain_code.strip!
                mol_codes[chain_code] = mol_id
                molecules[chain_code] = molecule
              end
            end

            ActiveRecord::Base.establish_connection(config)

            structure = Structure.create!(
              :pdb_code       => bio_pdb.accession,
              :classification => bio_pdb.classification,
              :title          => bio_pdb.definition,
              :exp_method     => bio_pdb.exp_method,
              :resolution     => (bio_pdb.resolution.to_f < EPSILON ? nil : bio_pdb.resolution),
              :r_value        => bio_pdb.r_value,
              :r_free         => bio_pdb.r_free,
              :space_group    => bio_pdb.space_group,
              :deposited_at   => bio_pdb.deposition_date
            )

            bio_model = bio_pdb.models.first

            model = structure.models.create(
              :model_code   => bio_model.serial ? bio_model.serial : 1
            )

            # Create empty atoms array for massive importing Atom AREs
            atoms = Array.new

            bio_model.each do |bio_chain|
              chain_code = bio_chain.chain_id.blank? ? nil : bio_chain.chain_id
              chain_type = if bio_chain.aa?
                             "aa_chains"
                           elsif bio_chain.dna?
                             "dna_chains"
                           elsif bio_chain.rna?
                             "rna_chains"
                           elsif bio_chain.hna?
                             "hna_chains"
                           else
                             "pseudo_chains"
                           end

              chain = model.send(chain_type).create(
                :chain_code => chain_code,
                :mol_code   => (mol_codes[chain_code] ? mol_codes[chain_code] : nil),
                :molecule   => (molecules[chain_code] ? molecules[chain_code] : nil)
              )

              bio_chain.each_residue do |bio_residue|
                if bio_residue.aa?
                  residue = chain.send("aa_residues").create(residue_params(bio_residue))
                elsif bio_residue.dna?
                  residue = chain.send("dna_residues").create(residue_params(bio_residue))
                elsif bio_residue.rna?
                  residue = chain.send("rna_residues").create(residue_params(bio_residue))
                elsif bio_residue.na?
                  residue = chain.send("na_residues").create(residue_params(bio_residue))
                else
                  raise "Error: #{bio_residue} is a unknown type of standard residue!"
                end
                bio_residue.each { |a| atoms << residue.atoms.build(atom_params(a)) }
              end

              bio_chain.each_heterogen do |bio_het_residue|
                residue = chain.send("het_residues").create(residue_params(bio_het_residue))
                bio_het_residue.each { |a| atoms << residue.atoms.build(atom_params(a)) }
              end
            end

            Atom.import(atoms, :validate => false)
            structure.save!
            $logger.info "Importing #{pdb_file}: done (#{i + 1}/#{pdb_files.size})"

            # Associate residues with SCOP domains
            domains = ScopDomain.find_all_by_pdb_code(pdb_code)

            if domains.empty?
              $logger.warn "No SCOP domains for #{pdb_code} (#{i+1}/#{pdb_files.size})"
            else
              domains.each do |domain|
                structure.models.first.aa_residues.each do |residue|
                  if domain.include? residue
                    residue.domain = domain
                    residue.save!
                  end
                end
              end
              $logger.info "Associating SCOP domains with #{pdb_code} (#{i+1}/#{pdb_files.size}): done"
            end
            ActiveRecord::Base.remove_connection
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end # task :pdb


    desc "Import NACCESS results into BIPA"
    task :naccess => [:environment] do

      pdb_codes = Structure.all.map(&:pdb_code).map(&:downcase)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        pdb_codes.each_with_index do |pdb_code, i|

          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)

            structure           = Structure.find_by_pdb_code(pdb_code.upcase)
            bound_asa_file      = File.join(NACCESS_DIR, "#{pdb_code}_co.asa")
            unbound_aa_asa_file = File.join(NACCESS_DIR, "#{pdb_code}_aa.asa")
            unbound_na_asa_file = File.join(NACCESS_DIR, "#{pdb_code}_na.asa")

            if (!File.size?(bound_asa_file)       ||
                !File.size?(unbound_aa_asa_file)  ||
                !File.size?(unbound_na_asa_file))
              $logger.warn "Skipped #{pdb_code}: no NACCESS result file"
              structure.no_naccess = true
              structure.save!
              next
            end

            bound_atom_asa      = Bipa::Naccess.new(IO.read(bound_asa_file)).atom_asa
            unbound_aa_atom_asa = Bipa::Naccess.new(IO.read(unbound_aa_asa_file)).atom_asa
            unbound_na_atom_asa = Bipa::Naccess.new(IO.read(unbound_na_asa_file)).atom_asa
            atom_radius         = Bipa::Naccess.new(IO.read(bound_asa_file)).atom_radius
            columns             = [:atom_id, :unbound_asa, :bound_asa, :delta_asa, :radius]
            values              = []

            %w[aa_atoms na_atoms].each do |atoms|
              structure.send(atoms).each do |atom|
                next if !bound_atom_asa.has_key?(atom.atom_code) || !unbound_aa_atom_asa.has_key?(atom.atom_code)

                # Uncomment following lines if you want to use import_with_load_data_in_file
                values << [
                  atom.id,
                  unbound_aa_atom_asa[atom.atom_code],
                  bound_atom_asa[atom.atom_code],
                  unbound_aa_atom_asa[atom.atom_code] - bound_atom_asa[atom.atom_code],
                  atom_radius[atom.atom_code]
                ]
              end
            end

            Naccess.import_with_load_data_infile(columns, values, :local => false)
            ActiveRecord::Base.remove_connection

            $logger.info "Importing #{pdb_code}.asa to 'naccess': done (#{i + 1}/#{pdb_codes.size})"
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


    desc "Import DSSP results to BIPA"
    task :dssp => [:environment] do

      pdb_codes = Structure.find(:all, :select => "pdb_code").map(&:pdb_code).map(&:downcase)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        pdb_codes.each_with_index do |pdb_code, i|

          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)

            structure = Structure.find_by_pdb_code(pdb_code.upcase)
            dssp_file = File.join(DSSP_DIR, "#{pdb_code}.dssp")
            dssps     = Array.new

            unless File.size?(dssp_file)
              $logger.warn "Skipped #{pdb_code}: no DSSP result file"
              structure.no_dssp = true
              structure.save!
              next
            end

            dssp_residues = Bipa::Dssp.new(IO.read(dssp_file)).residues

            structure.models.first.aa_residues.each do |residue|
              key = residue.residue_code.to_s +
                (residue.icode.blank? ? '' : residue.icode) +
                residue.chain.chain_code

              residue.create_dssp(dssp_residues[key].to_hash) if dssp_residues.has_key?(key)
            end

            ActiveRecord::Base.remove_connection

            $logger.info "Importing #{pdb_code}.dssp to 'dssp': done (#{i + 1}/#{pdb_codes.size})"
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


    desc "Import OpenEYE ZAP results to BIPA"
    task :zap => [:environment] do

      pdb_codes = Structure.all.map(&:pdb_code).map(&:downcase)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        pdb_codes.each_with_index do |pdb_code, i|

          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)

            structure   = Structure.find_by_pdb_code(pdb_code.upcase)
            ZapAtom     = Struct.new(:radius, :formal_charge, :partial_charge, :potential)
            aa_zap_file = File.join(ZAP_DIR, "#{pdb_code}_aa.zap")
            na_zap_file = File.join(ZAP_DIR, "#{pdb_code}_na.zap")
            aa_zap_err  = File.join(ZAP_DIR, "#{pdb_code}_aa.err")
            na_zap_err  = File.join(ZAP_DIR, "#{pdb_code}_na.err")
            zap_atoms   = Hash.new
            zaps        = Array.new
            tainted_zap = false

            if (!File.size?(aa_zap_file)  ||
                !File.size?(na_zap_file)  ||
                File.size?(aa_zap_err)    ||
                File.size?(na_zap_err))
              $logger.warn "Skipped #{pdb_code}: no ZAP result file"
              structure.no_zap = true
              structure.save!
              next
            end

            IO.foreach(aa_zap_file) do |line|
              z = line.chomp.split(/\s+/)
              unless z.size == 7
                tainted_zap = true
                break
              end
              zap_atoms[z[1].to_i] = ZapAtom.new(z[3].to_f, z[4].to_f, z[5].to_f, z[6].to_f)
            end

            IO.foreach(na_zap_file) do |line|
              z = line.chomp.split(/\s+/)
              unless z.size == 7
                tainted_zap = true
                break
              end
              zap_atoms[z[1].to_i] = ZapAtom.new(z[3].to_f, z[4].to_f, z[5].to_f, z[6].to_f)
            end

            if tainted_zap
              $logger.warn "Skipped #{pdb_code}: abnormal ZAP results"
              structure.no_zap = true
              structure.save!
              next
            end

            structure.atoms.each do |atom|
              zaps << atom.build_zap(zap_atoms[atom.atom_code].to_hash) if zap_atoms.has_key?(atom.atom_code)
            end

            Zap.import(zaps, :validate => false)
            ActiveRecord::Base.remove_connection
            $logger.info "Importing 'zap' for #{pdb_code}: done (#{i + 1}/#{pdb_codes.size})"
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


    desc "Import van der Waals Contacts"
    task :vdw_contacts => [:environment] do

      pdb_codes = Structure.find(:all, :select => "pdb_code").map(&:pdb_code)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        pdb_codes.each_with_index do |pdb_code, i|

          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)

            structure = Structure.find_by_pdb_code(pdb_code)
            kdtree    = Bipa::Kdtree.new
            columns   = [:atom_id, :vdw_contacting_atom_id, :distance]
            values    = []

            structure.atoms.each { |a| kdtree.insert(a) }

            aa_atoms = structure.aa_atoms
            na_atoms = structure.na_atoms

            na_atoms.each do |na_atom|
              neighbor_atoms = kdtree.neighbors(na_atom, MAX_VDW_DISTANCE).map(&:point)
              neighbor_atoms.each do |neighbor_atom|
                if neighbor_atom.aa?
                  dist = na_atom - neighbor_atom
                  if (!Hbond.exists?(:donor_id => neighbor_atom.id, :acceptor_id => na_atom.id) &&
                      !Hbond.exists?(:donor_id => na_atom.id, :acceptor_id => neighbor_atom.id))
                    values << [neighbor_atom.id, na_atom.id, dist]
                  end
                end
              end
            end

            VdwContact.import_with_load_data_infile(columns, values, :local => false)
            ActiveRecord::Base.remove_connection

            $logger.info "Importing #{values.size} van der Waals contacts in #{pdb_code} to 'vdw_contacts' table: done (#{i + 1}/#{pdb_codes.size})"
          end
          ActiveRecord::Base.establish_connection(config)
        end
      end
    end


    desc "Import HBPlus results into BIPA"
    task :hbplus => [:environment] do

      pdb_codes = Structure.find(:all, :select => "pdb_code").map(&:pdb_code)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        pdb_codes.each_with_index do |pdb_code, i|

          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)

            structure   = Structure.find_by_pdb_code(pdb_code)
            hbplus_file = File.join(HBPLUS_DIR, "#{pdb_code.downcase}.hb2")
            bipa_hbonds = Bipa::Hbplus.new(IO.read(hbplus_file)).hbonds
            columns     = [
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
            values      = []

            if !File.size?(hbplus_file) || bipa_hbonds.empty?
              $logger.warn "Skipped #{pdb_code}: (maybe) C-alpha only structure"
              structure.no_hbplus = true
              structure.save!
              next
            end

            bipa_hbonds.each do |hbond|
              begin
                donor_chain   = structure.models.first.chains.find_by_chain_code(hbond.donor.chain_code)
                donor_residue = donor_chain.residues.find_by_residue_code_and_icode(hbond.donor.residue_code, hbond.donor.insertion_code)
                donor_atom    = donor_residue.atoms.find_by_atom_name(hbond.donor.atom_name)

                if hbond.donor.residue_name =~ /CSS/
                  donor_residue.ss = true
                  donor_residue.save!
                  $logger.info "*** Disulfide bonding cysteine found"
                end

                acceptor_chain   = structure.models.first.chains.find_by_chain_code(hbond.acceptor.chain_code)
                acceptor_residue = acceptor_chain.residues.find_by_residue_code_and_icode(hbond.acceptor.residue_code, hbond.acceptor.insertion_code)
                acceptor_atom    = acceptor_residue.atoms.find_by_atom_name(hbond.acceptor.atom_name)

                if hbond.acceptor.residue_name =~ /CSS/
                  acceptor_residue.ss = true
                  acceptor_residue.save!
                  $logger.info "Disulfide bonding cysteine found!"
                end
              rescue
                $logger.warn "Cannot find hbplus: #{hbond.donor} <=> #{hbond.acceptor} in #{pdb_code}"
                next
              else
                if donor_atom && acceptor_atom
                  if Hbplus.exists?(:donor_id => donor_atom.id, :acceptor_id => acceptor_atom.id)
                    $logger.warn "Skipped hbplus: #{donor_atom.id} <=> #{acceptor_atom.id} in #{pdb_code}"
                    next
                  else
                    values << [
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

            Hbplus.import_with_load_data_infile(columns, values, :local => false)
            ActiveRecord::Base.remove_connection
            $logger.info "Importing #{values.size} hbonds in #{pdb_code.downcase}.hb2 to 'hbplus' table: done (#{i + 1}/#{pdb_codes.size})"
          end # fmanager.fork
        end # pdb_codes.each_with_index
        ActiveRecord::Base.establish_connection(config)
      end # fmanager.manage
    end


    desc "Import hydrogen bonds between protein and nucleic acids"
    task :hbonds => [:environment] do

      pdb_codes = Structure.untainted.map(&:pdb_code)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        pdb_codes.each_with_index do |pdb_code, i|

          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)

            structure = Structure.find_by_pdb_code(pdb_code)
            columns   = [:donor_id, :acceptor_id, :hbplus_id]
            values    = []

            structure.hbplus_as_donor.each do |hbplus|
              if ((hbplus.donor.aa? && hbplus.acceptor.na?) ||
                  (hbplus.donor.na? && hbplus.acceptor.aa?))
                values << [hbplus.donor.id, hbplus.acceptor.id, hbplus.id]
              end
            end

            Hbond.import_with_load_data_infile(columns, values, :local => false) unless values.empty?
            ActiveRecord::Base.remove_connection

            $logger.info "Importing #{values.size} hbonds in #{pdb_code} into 'hbonds' table: done (#{i + 1}/#{pdb_codes.size})"
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


    desc "Import Water-mediated hydrogen bonds"
    task :whbonds => [:environment] do

      require "facets/array"

      pdb_codes = Structure.untainted.map(&:pdb_code)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        pdb_codes.each_with_index do |pdb_code, i|

          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)

            structure = Structure.find_by_pdb_code(pdb_code)
            columns   = [:atom_id, :whbonding_atom_id, :water_atom_id, :aa_water_hbond_id, :na_water_hbond_id]
            values    = []

            structure.water_atoms.each do |water|
              water.hbplus_donors.combination(2).each do |atom1, atom2|
                if atom1.aa? && atom2.na?
                  values << [atom1.id, atom2.id, water.id,
                    atom1.hbplus_as_donor.find_by_acceptor_id(water).id,
                    atom2.hbplus_as_donor.find_by_acceptor_id(water).id]
                elsif atom1.na? && atom2.aa?
                  values << [atom2.id, atom1.id, water.id,
                    atom2.hbplus_as_donor.find_by_acceptor_id(water).id,
                    atom1.hbplus_as_donor.find_by_acceptor_id(water).id]
                end
              end

              water.hbplus_acceptors.combination(2).each do |atom1, atom2|
                if atom1.aa? && atom2.na?
                  values << [atom1.id, atom2.id, water.id,
                    atom1.hbplus_as_acceptor.find_by_donor_id(water).id,
                    atom2.hbplus_as_acceptor.find_by_donor_id(water).id]
                elsif atom1.na? && atom2.aa?
                  values << [atom2.id, atom1.id, water.id,
                    atom2.hbplus_as_acceptor.find_by_donor_id(water).id,
                    atom1.hbplus_as_acceptor.find_by_donor_id(water).id]
                end
              end

              water.hbplus_donors.each do |atom1|
                water.hbplus_acceptors.each do |atom2|
                  if atom1.aa? && atom2.na?
                    values << [atom1.id, atom2.id, water.id,
                      atom1.hbplus_as_donor.find_by_acceptor_id(water).id,
                      atom2.hbplus_as_acceptor.find_by_donor_id(water).id]
                  elsif atom1.na? && atom2.aa?
                    values << [atom2.id, atom1.id, water.id,
                      atom2.hbplus_as_acceptor.find_by_donor_id(water).id,
                      atom1.hbplus_as_donor.find_by_acceptor_id(water).id]
                  end
                end
              end
            end

            Whbond.import_with_load_data_infile(columns, values, :local => false) unless values.empty?
            ActiveRecord::Base.remove_connection

            $logger.info "Importing #{values.size} water-mediated hbonds in #{pdb_code} to 'whbonds' table: done (#{i + 1}/#{pdb_codes.size})"
          end # fmanager.fork
        end # pdb_codes.each_with_index
        ActiveRecord::Base.establish_connection(config)
      end # fmanager.manage
    end


    desc "Import Domain Interfaces"
    task :domain_interfaces => [:environment] do

      pdb_codes = Structure.untainted.map(&:pdb_code)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection
        pdb_codes.each_with_index do |pdb_code, i|
          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)

            domains = ScopDomain.find_all_by_pdb_code(pdb_code)
            domains.each do |domain|
              %w[dna rna].each do |na|
                iface_found = false

                if domain.send("#{na}_interfaces").size > 0
                  $logger.warn "#{domain.sid} has a already detected #{na} interface"
                  iface_found = true
                  next
                end

                if domain.send("#{na}_binding_interface_residues").size > 0
                  iface = "Domain#{na.camelize}Interface".constantize.new
                  iface.domain = domain
                  iface.residues << domain.send("#{na}_binding_interface_residues")
                  iface.save!
                  iface_found = true
                  $logger.info "#{domain.sid} has a #{na} interface"
                end

                if iface_found == true
                  domain.rpall = true
                  domain.send("rpall_#{na}=", true)
                  domain.save!
                  domain.ancestors.each do |anc|
                    anc.rpall = true
                    anc.send("rpall_#{na}=", true)
                    anc.save!
                  end
                end
              end
            end # domains.each

            ActiveRecord::Base.remove_connection
            $logger.info "Extracting domain interfaces from #{pdb_code}: done (#{i + 1}/#{pdb_codes.size})"
          end # fmanager.fork
        end # pdb_codes.each_with_index
        ActiveRecord::Base.establish_connection(config)
      end # fmanager.manage
    end


    desc "Import Chain Interfaces"
    task :chain_interfaces => [:environment] do

      pdb_codes = Structure.untainted.map(&:pdb_code)
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

      %w[dna rna].each do |na|
        #sunids    = ScopFamily.send("rpall_#{na}").map(&:sunid).sort
        sunids    = ScopFamily.send("rpall_#{na}").select { |sf| TRUE_SCOP_CLASSES.include?(sf.sccs[0].chr) }.map(&:sunid).sort
        fmanager  = ForkManager.new(MAX_FORK)

        fmanager.manage do
          config = ActiveRecord::Base.remove_connection

          sunids.each_with_index do |sunid, i|
            fmanager.fork do
              ActiveRecord::Base.establish_connection(config)

              family  = ScopFamily.find_by_sunid(sunid)
              fam_dir = File.join(BLASTCLUST_DIR, na, "#{sunid}")

              (10..100).step(10) do |pid|
                subfam_file = File.join(fam_dir, "#{sunid}.cluster#{pid}")

                IO.readlines(subfam_file).each do |line|
                  subfamily = "Nr#{pid}#{na.capitalize}BindingSubfamily".constantize.new
                  members   = line.split(/\s+/)
                  members.each do |member|
                    domain = ScopDomain.find_by_sunid(member)
                    if domain
                      subfamily.domains << domain
                    else
                      $logger.warn "!!! Cannot find SCOP domain, #{member}"
                      exit 1
                    end
                  end
                  subfamily.family = family
                  subfamily.save!
                end
              end

              ActiveRecord::Base.remove_connection
              $logger.info ">>> Importing subfamilies for #{na.upcase}-binding SCOP family, #{sunid}: done (#{i + 1}/#{sunids.size})"
            end
          end
          ActiveRecord::Base.establish_connection(config)
        end
      end
    end


    desc "Import Full & Representative Alignments for each SCOP Family"
    task :full_alignments => [:environment] do

      %w[dna rna].each do |na|
        sunids    = ScopFamily.send("rpall_#{na}").map(&:sunid).sort
        fmanager  = ForkManager.new(MAX_FORK)

        fmanager.manage do
          config = ActiveRecord::Base.remove_connection
          sunids.each_with_index do |sunid, i|
            fmanager.fork do
              ActiveRecord::Base.establish_connection(config)

              family    = ScopFamily.find_by_sunid(sunid)
              fam_dir   = File.join(FAMILY_DIR, "full", na, sunid.to_s)
              ali_files = FileList[fam_dir + "/cluster*.ali*"]

              if ali_files.size < 1
                $logger.error "Cannot find any Baton alignment files (e.g. baton.ali0)"
                exit 1
              end

              ali_files.each do |ali_file|
                alignment = family.send("full_#{na}_binding_family_alignments").create
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
                    column    = alignment.columns.find_or_create_by_number(fi + 1)
                    position  = sequence.positions.build

                    if (res == "-")
                      position.residue_name = res
                      position.number       = fi + 1
                      position.column       = column
                      position.save!
                    else
                      if db_residues[pos].nil?
                        $logger.error "!!! Position #{pos}, #{res} is nil in #{domain.sid}, #{domain.sunid}"
                        exit 1
                      elsif db_residues[pos].one_letter_code == res
                        position.residue      = db_residues[pos]
                        position.residue_name = res
                        position.number       = fi + 1
                        position.column       = column
                        position.save!
                        pos += 1
                      else
                        $logger.error "!!! Mismatch at #{pos}, between #{res} and #{db_residues[pos].one_letter_code} of #{domain.sid}, #{domain.sunid}"
                        exit 1
                      end
                    end
                  end # ff_residues.each_with_index
                  sequence.save!
                end # flat_file.each_entry
                alignment.save!
              end

              ActiveRecord::Base.remove_connection
              $logger.info ">>> Importing full alignments of #{na.upcase}-binding SCOP family, #{sunid}: done (#{i + 1}/#{sunids.size})"
            end # fmanger.fork
          end
          ActiveRecord::Base.establish_connection(config)
        end # sunids.each
      end # fmanager.manage
    end # task :full_alignments


    desc "Import representative alignments for each SCOP Family"
    task :nr_alignments => [:environment] do

      %w[dna rna].each do |na|
        sunids    = ScopFamily.send("rpall_#{na}").map(&:sunid).sort
        fmanager  = ForkManager.new(MAX_FORK)

        fmanager.manage do
          config = ActiveRecord::Base.remove_connection

          (10..100).step(10) do |pid|
            sunids.each_with_index do |sunid, i|
              fmanager.fork do
                ActiveRecord::Base.establish_connection(config)

                family      = ScopFamily.find_by_sunid(sunid)
                family_dir  = File.join(FAMILY_DIR, "nr#{pid}", na, "#{family.sunid}")
                ali_file    = File.join(family_dir, "baton.ali")

                unless File.exists?(ali_file)
                  $logger.warn "!!! Cannot find #{ali_file} for #{na.upcase}-binding SCOP family, #{sunid}"
                  next
                end

                alignment = family.send("create_nr#{pid}_#{na}_binding_family_alignment")
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
                    column    = alignment.columns.find_or_create_by_number(fi + 1)
                    position  = sequence.positions.build

                    if (res == "-")
                      position.residue_name = res
                      position.number       = fi + 1
                      position.column       = column
                      position.save!
                      column.save!
                    else
                      if (db_residues[pos].one_letter_code == res)
                        position.residue      = db_residues[pos]
                        position.residue_name = res
                        position.number       = fi + 1
                        position.column       = column
                        position.save!
                        column.save!
                        pos += 1
                      else
                        $logger.error "Mismatch at #{pos}, between #{res} and #{db_residues[pos].one_letter_code} of #{domain.sid}, #{domain.sunid}"
                        exit 1
                      end
                    end
                  end # ff_residues.each_with_index
                  sequence.save!
                end # flat_file.each_entry
                alignment.save!
                ActiveRecord::Base.remove_connection
                $logger.info "Importing non-redundant (PID: #{pid}) alignments for #{na.upcase}-binding SCOP family, #{sunid}: done (#{i + 1}/#{sunids.size})"
              end # fmanager.fork
            end # sunids.each
          end # (30..100).step(10)
          ActiveRecord::Base.establish_connection(config)
        end # fmanager.manage
      end # %w[dna rna].each # fmanager.manage
    end # task :alignments


    desc "Import subfamily alignments for each SCOP Family"
    task :sub_alignments => [:environment] do

      %w[dna rna].each do |na|
        sunids    = ScopFamily.send("rpall_#{na}").map(&:sunid).sort
        fmanager  = ForkManager.new(MAX_FORK)

        fmanager.manage do
          config = ActiveRecord::Base.remove_connection

          sunids.each_with_index do |sunid, i|
            fmanager.fork do
              ActiveRecord::Base.establish_connection(config)

              family      = ScopFamily.find_by_sunid(sunid)
              rep_dir     = File.join(FAMILY_DIR, "sub", na, sunid.to_s)
              subfam_ids  = Dir[rep_dir + "/*"].map { |d| d.match(/(\d+)$/)[1] }

              subfam_ids.each do |subfam_id|
                ali_file = File.join(rep_dir, subfam_id, "baton.ali")

                unless File.exists?(ali_file)
                  $logger.warn "!!! Cannot find #{ali_file} for Subfamily, #{subfam_id} of #{na.upcase}-binding SCOP family, #{sunid}"
                  next
                end

                alignment = Subfamily.find(subfam_id).create_alignment
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
                    column    = alignment.columns.find_or_create_by_number(fi + 1)
                    position  = sequence.positions.build

                    if (res == "-")
                      position.residue_name = res
                      position.number       = fi + 1
                      position.column       = column
                      position.save!
                      column.save!
                    else
                      if (db_residues[pos].one_letter_code == res)
                        position.residue      = db_residues[pos]
                        position.residue_name = res
                        position.number       = fi + 1
                        position.column       = column
                        position.save!
                        column.save!
                        pos += 1
                      else
                        $logger.error "!!! Mismatch at #{pos}, between #{res} and #{db_residues[pos].one_letter_code} of #{domain.sid}"
                        exit 1
                      end
                    end
                  end # ff_residues.each_with_index
                  sequence.save!
                end # flat_file.each_entry
                alignment.save!
              end # subfam_ids.each

              ActiveRecord::Base.remove_connection
              $logger.info ">>> Importing subfamily alignments of #{na.upcase}-binding SCOP family, #{sunid}: done (#{i + 1}/#{sunids.size})"
            end # fmanager.fork
          end # sunids.each

          ActiveRecord::Base.establish_connection(config)
        end # fmanager.manage
      end # %w[dna rna].each
    end # task :sub_alignments


    desc "Import GO data into 'go_terms' and 'go_relationships' tables"
    task :go_terms => [:environment] do

      obo_file  = File.join(GO_DIR, "gene_ontology_edit.obo")
      obo_obj   = Bipa::Obo.new(IO.read(obo_file))

      obo_obj.terms.each do |go_id, term|
        term_ar = GoTerm.find_by_go_id(go_id)
        if term_ar.nil?
          GoTerm.create!(term.to_hash)
          $logger.info "Importing #{go_id} to 'go_terms': done"
        end
      end

      obo_obj.relationships.each do |go_id, relationships|
        source = GoTerm.find_by_go_id(go_id)

        relationships.each do |relationship|
          target = GoTerm.find_by_go_id(relationship.target_id)

          if relationship.type == "is_a"
            GoIsA.create!(:source_id => source.id, :target_id => target.id)
            $logger.info "Importing #{go_id} 'is_a' #{relationship.target_id} into 'go_relationships': done"
          elsif relationship.type == "part_of"
            GoPartOf.create!(:source_id => source.id, :target_id => target.id)
            $logger.info "Importing #{go_id} 'part_of' #{relationship.target_id} into 'go_relationships': done"
          elsif relationship.type == "regulates"
            GoRegulates.create!(:source_id => source.id, :target_id => target.id)
            $logger.info "Importing #{go_id} 'regulates' #{relationship.target_id} into 'go_relationships': done"
          elsif relationship.type == "positively_regulates"
            GoPositivelyRegulates.create!(:source_id => source.id, :target_id => target.id)
            $logger.info "Importing #{go_id} 'positively regulates' #{relationship.target_id} into 'go_relationships': done"
          elsif relationship.type == "negatively_regulates"
            GoNegativelyRegulates.create!(:source_id => source.id, :target_id => target.id)
            $logger.info "Importing #{go_id} 'negatively regulates' #{relationship.target_id} into 'go_relationships': done"
          else
            raise "Unknown type of relationship: #{relationship.type}"
          end
        end
      end
    end


    desc "Import GOA-PDB data into 'goa_pdbs' table"
    task :goa => [:environment] do

      goa_pdb_file = File.join(GO_DIR, "gene_association.goa_pdb")

      IO.foreach(goa_pdb_file) do |line|
        line_arr = line.chomp.split(/\t/)
        line_hsh = {
          :db               => line_arr[0],
          :db_object_id     => line_arr[1],
          :db_object_symbol => line_arr[2],
          :qualifier        => line_arr[3].nil_if_blank,
          :go_id            => line_arr[4],
          :db_reference     => line_arr[5],
          :evidence         => line_arr[6],
          :with             => line_arr[7],
          :aspect           => line_arr[8],
          :db_object_name   => line_arr[9].nil_if_blank,
          :synonym          => line_arr[10].nil_if_blank,
          :db_object_type   => line_arr[11],
          :taxon_id         => line_arr[12].gsub(/taxon:/, ''),
          :date             => line_arr[13],
          :assigned_by      => line_arr[14]
        }

        pdb_code    = line_hsh[:db_object_id].match(/\S{4}/)[0]
        chain_code  = line_hsh[:db_object_id].match(/\S{4}_(\S{1})/)[1]
        structure   = Structure.find_by_pdb_code(pdb_code)

        next if structure.nil?

        chain   = structure.chains.find_by_chain_code(chain_code)
        go_term = GoTerm.find_by_go_id(line_hsh[:go_id])

        GoaPdb.create!({:chain_id => chain.id, :go_term_id => go_term.id }.merge!(line_hsh))
        $logger.info "Importing #{pdb_code}, #{chain_code}, #{line_hsh[:go_id]} into 'goa_pdbs' table: done"
      end
    end


    desc "Import NCBI Taxonomy 'nodes.dmp' file into 'taxonomic_nodes' table"
    task :taxonomic_nodes => [:environment] do
      ActiveRecord::Base.connection.execute(
        <<-SQL
          LOAD DATA INFILE "#{File.join(RAILS_ROOT, './public/taxonomy/nodes.dmp')}"
          IGNORE INTO TABLE taxonomic_nodes
          FIELDS TERMINATED BY '\t|\t'
          LINES  TERMINATED BY '\t|\n';
        SQL
      )

      $logger.info "Importing nodes.dmp into 'taxonomic_nodes' table: done"

      #      nodes_file = File.join(TAXONOMY_DIR, "nodes.dmp")
      #
      #      Node = Struct.new(
      #        :id,
      #        :parent_id,
      #        :rank,
      #        :embl_code,
      #        :division_id,
      #        :inherited_div_flag,
      #        :genetic_code_id,
      #        :inherited_gc_flag,
      #        :mitochondrial_genetic_code_id,
      #        :inherited_mgc_flag,
      #        :genbank_hidden_flag,
      #        :hidden_subtree_root,
      #        :comments
      #      )

      #      IO.foreach(nodes_file) do |line|
      #        next if line =~ /^#/ || line.blank?
      #        node_struct = Node.new(*line.gsub(/\t\|\n$/,"").split(/\t\|\t/))
      #        TaxonomicNode.create!(node_struct.to_hash)
      #      end

      #      nodes = TaxonomicNode.find(:all, :select => "id, parent_id, lft, rgt, tax_id, parent_tax_id")
      #      nodes.each_with_index do |node, i|
      #        next if node.tax_id == 1;
      #        parent = TaxonomicNode.find_by_tax_id(node.parent_tax_id)
      #        node.move_to_child_of(parent)
      #        $logger.info("Importing #{node.id} into 'nodes' table: done (#{i + 1}/#{nodes.size})")
      #      end
    end


    desc "Import NCBI Taxonomy 'names.dmp' file into 'taxonomic_names' table"
    task :taxonomic_names => [:environment] do
      ActiveRecord::Base.connection.execute(
        <<-SQL
          LOAD DATA INFILE "#{File.join(RAILS_ROOT, './public/taxonomy/names.dmp')}"
          IGNORE INTO TABLE taxonomic_names
          FIELDS TERMINATED BY '\t|\t'
          LINES  TERMINATED BY '\t|\n'
          (taxonomic_node_id, name_txt, unique_name, name_class);
        SQL
      )

      $logger.info "Importing names.dmp into 'taxonomic_names' table: done"

      #      name_file = File.join(TAXONOMY_DIR, "names.dmp")
      #
      #      Name = Struct.new(
      #        :tax_id,
      #        :name_txt,
      #        :unique_name,
      #        :name_class
      #      )
      #
      #      IO.foreach(names_file) do |line|
      #        next if line =~ /^#/ || line.blank?
      #        name = Name.new(*line.gsub(/\t\|\n$/,"").split(/\t\|\t/))
      #        node = TaxonomicNode.find_by_tax_id(name.tax_id)
      #        node.names.create!(name.to_hash)
      #      end
    end


    desc "Import ESSTs"
    task :essts => [:environment] do

      (10..100).step(10) do |si|
        next unless si == 90

        rep_dir       = File.join(ESST_DIR, "rep#{si}")
        na_esst_dir   = File.join(rep_dir, "na")
        std_esst_dir  = File.join(rep_dir, "std")

        [na_esst_dir, std_esst_dir].each_with_index do |esst_dir, i|
          tag = false
          esst = nil
          colnames = nil
          esst_class = (i == 0 ? NaEsst : StdEsst)

          prob_mat = File.join(esst_dir, "allmat.dat.prob")

          IO.foreach(prob_mat) do |line|
            case line
            when /^#/
              colnames = line.gsub(/#/, '').strip.split(/\s+/) if tag
              next
            when /^>(\w+)\s+(\d+)$/
              tag = true
              env, num = $1, $2
              $logger.info "Importing Probability ESST, #{num} under #{env} ..."
              if (env == "total")
                esst = esst_class.create!(:redundancy => 90,
                                          :number => num,
                                          :environment => env)
              else
                esst = esst_class.create!(:redundancy => 90,
                                          :number => num,
                                          :environment => env,
                                          :secondary_structure => env[0].chr,
                                          :solvent_accessibility => env[1].chr,
                                          :hbond_to_sidechain => env[2].chr,
                                          :hbond_to_mainchain_carbonyl => env[3].chr,
                                          :hbond_to_mainchain_amide => env[4].chr,
                                          :dna_rna_interface => (i == 0 ? env[5].chr : nil))
              end
            when /^(\w)\s+(.*)$/
              rowname, cells = $1, $2.strip.split(/\s+/)
              cells.each_with_index do |cell, j|
                esst.substitutions << Substitution.create!(:aa1 => rowname,
                                                           :aa2 => colnames[j],
                                                           :prob => cell.to_f)
              end
            end # case line
          end # IO.foreach(prob_mat)

          log_mat = File.join(esst_dir, "allmat.dat.log")

          IO.foreach(log_mat) do |line|
            case line
            when /^#/
              colnames = line.gsub(/#/, '').strip.split(/\s+/) if tag
              next
            when /^>(\w+)\s+(\d+)$/
              tag = true
              env, num = $1, $2
              $logger.info "Importing Log Odds Ratio ESST, #{num} under #{env} ..."
              esst = esst_class.find_by_redundancy_and_number(90, num)
            when /^(\w)\s+(.*)$/
              rowname, cells = $1, $2.strip.split(/\s+/)
              cells.each_with_index do |cell, j|
                if sub = esst.substitutions.find_by_aa1_and_aa2(rowname, colnames[j])
                  sub.log = cell.to_i
                  sub.save!
                end
              end
            end # case line
          end # IO.foreach(log_mat)

          raw_cnts  = Dir[esst_dir + "/rawc*"]

          raw_cnts.each do |raw_cnt|
            num   = raw_cnt.match(/rawc(\d+)/)[1].to_i - 1
            esst  = esst_class.find_by_redundancy_and_number(90, num)
            cnts  = []

            $logger.info "Importing Count ESST, #{num} ..."

            IO.foreach(raw_cnt) { |l| cnts.concat(l.strip.gsub(/\./,'').split(/\s+/)) }
            esst.substitutions.each_with_index { |s, k| s.cnt = cnts[k].to_i; s.save! }
          end
        end # [na_esst_dir, std_esst_dir].each
      end
    end


    desc "Import Fugue profiles"
    task :profiles => [:environment] do
      (10..100).step(10) do |si|
        rep_dir       = File.join(ESST_DIR, "rep#{si}")
        na_esst_dir   = File.join(rep_dir, "na")
        std_esst_dir  = File.join(rep_dir, "std")

        [na_esst_dir, std_esst_dir].each_with_index do |esst_dir, i|
          prfs = FileList[esst_dir + "/*.fug"]
          prfs.each do |prf|
            name                      = File.basename(prf, ".fug")
            alignment                 = Scop.find_by_sunid(name).send(:"rep#{si}_alignment")
            command                   = nil #Command:                       melody -list TEMLIST -c classdef.dat -s allmat.dat.log.pid100
            length                    = nil #Profile_length:                120   alignment positions
            no_sequences              = nil #Sequence_in_profile:           3     sequences
            no_structures             = nil #Real_Structure:                3     structures
            enhance_num               = nil #Enhance_Num:                   3     sequences
            enhance_div               = nil #Enhance_Div:                   0.549
            weighting                 = nil #Weighting:                     1  BlosumWeight -- weighting scheme based on single linkage clustering
            weighting_threshold       = nil #Weighting_threshold:           0
            weighting_seed            = nil #Weighting_seed:                -488943
            multiple_factor           = nil #Multiple_factor:               10.0
            format                    = nil #Profile_format:                0      FUGUE
            similarity_matrix         = nil #Similarity_matrix:             OFF
            similarity_matrix_offset  = nil #Similarity_matrix_offset:      NONE
            ignore_gap_weight         = nil #Ignore_gap_weight:             ON
            symbol_in_row             = nil #Symbol_in_row(sequence):       ACDEFGHIKLMNPQRSTVWYJU
            symbol_in_column          = nil #Symbol_in_column(structure):   ACDEFGHIKLMNPQRSTVWYJ
            symbol_structural_feature = nil #Symbol_structural_feature:     HEPCAaSsOoNnDRN
            gap_ins_open_terminal     = nil #GapInsOpenTerminal             100
            gap_del_open_terminal     = nil #GapDelOpenTerminal             100
            gap_ins_ext_terminal      = nil #GapInsExtTerminal              100
            gap_del_ext_terminal      = nil #GapDelExtTerminal              100
            evd                       = nil #EVD                            0
            start                     = false #START
            theend                    = false #THEEND
            profile_class             = (i == 0 ? NaProfile : StdProfile)
            profile_column_class      = (i == 0 ? NaProfileColumn : StdProfileColumn)
            profile                   = nil
            cnt                       = 0

            IO.foreach(prf) do |line|
              case line.chomp!
              when /^Command:\s+(.*)/                         then command = $1
              when /^Profile_length:\s+(\d+)/                 then length = $1
              when /^Sequence_in_profile:\s+(\d+)/            then no_sequences = $1
              when /^Real_Structure:\s+(\d+)/                 then no_structures = $1
              when /^Enhance_Num:\s+(\d+)/                    then enhance_num = $1
              when /^Enhance_Div:\s+(\S+)/                    then enhance_div = $1
              when /^Weighting:\s+(\d+)/                      then weighting = $1
              when /^Weighting_threshold:\s+(\d+)/            then weighting_threshold = $1
              when /^Weighting_seed:\s+(\S+)/                 then weighting_seed = $1
              when /^Multiple_factor:\s+(\S+)/                then multiple_factor = $1
              when /^Profile_format:\s+(\d+)/                 then format = $1
              when /^Similarity_matrix:\s+(\S+)/             then similarity_matrix = $1
              when /^Similarity_matrix_offset:\s+(\S+)/       then similarity_matrix_offset = $1
              when /^Ignore_gap_weight:\s+(\S+)/              then ignore_gap_weight = $1
              when /^Symbol_in_row\(sequence\):\s+(\S+)/      then symbol_in_row =  $1
              when /^Symbol_in_column\(structure\):\s+(\S+)/  then symbol_in_column = $1
              when /^Symbol_structural_feature:\s+(\S+)/      then symbol_structural_feature = $1
              when /^GapInsOpenTerminal\s+(\d+)/              then gap_ins_open_terminal = $1
              when /^GapDelOpenTerminal\s+(\d+)/              then gap_del_open_terminal = $1
              when /^GapInsExtTerminal\s+(\d+)/               then gap_ins_ext_terminal = $1
              when /^GapDelExtTerminal\s+(\d+)/               then gap_del_ext_terminal = $1
              when /^EVD\s+(\d+)/                             then evd = $1
              when /^START/                                   then start = true
              when /^THEEND/                                  then theend = true
              when /^(\S+)\s+(.*)$/
                if start and !theend
                  cnt += 1
                  seq, values = $1, $2.chomp.split(/\s+/)

                  if profile
                    profile.profile_columns << profile_column_class.create!(
                      :column_id => alignment.columns[cnt - 1].id, :seq => seq,
                      :aa_A => values[0], :aa_C => values[1], :aa_D => values[2], :aa_E => values[3],
                      :aa_F => values[4], :aa_G => values[5], :aa_H => values[6], :aa_I => values[7],
                      :aa_K => values[8], :aa_L => values[9], :aa_M => values[10],:aa_N => values[11],
                      :aa_P => values[12],:aa_Q => values[13],:aa_R => values[14],:aa_S => values[15],
                      :aa_T => values[16],:aa_V => values[17],:aa_W => values[18],:aa_Y => values[19],
                      :aa_J => values[20],:aa_U => values[21],
                      :InsO => values[22],:InsE => values[23],:DelO => values[24],:DelE => values[25],
                      :COIL => values[26],:HNcp => values[27],:HCcp => values[28],:HIn => values[29],
                      :SNcp => values[30],:SCcp => values[31],:SInt => values[32],:NRes => values[33],
                      :Ooi  => values[34], :Acc => values[35],
                      :H    => values[36],   :E => values[37],   :P => values[38],   :C => values[39],
                      :At   => values[40],  :Af => values[41],  :St => values[42],  :Sf => values[43],
                      :Ot   => values[44],  :Of => values[45],  :Nt => values[46],  :Nf => values[47],
                      :D    => (i == 0 ? values[48] : nil),
                      :R    => (i == 0 ? values[49] : nil),
                      :N    => (i == 0 ? values[50] : nil))
                  else
                    profile = profile_class.create!(:name                       => name,
                                                    :command                    => command,
                                                    :length                     => length,
                                                    :no_sequences               => no_sequences,
                                                    :no_structures              => no_structures,
                                                    :enhance_num                => enhance_num,
                                                    :enhance_div                => enhance_div,
                                                    :weighting                  => weighting,
                                                    :weighting_threshold        => weighting_threshold,
                                                    :weighting_seed             => weighting_seed,
                                                    :multiple_factor            => multiple_factor,
                                                    :format                     => format,
                                                    :similarity_matrix          => similarity_matrix,
                                                    :similarity_matrix_offset   => similarity_matrix_offset,
                                                    :ignore_gap_weight          => ignore_gap_weight,
                                                    :symbol_in_row              => symbol_in_row,
                                                    :symbol_in_column           => symbol_in_column,
                                                    :symbol_structural_feature  => symbol_structural_feature,
                                                    :gap_ins_open_terminal      => gap_ins_open_terminal,
                                                    :gap_del_open_terminal      => gap_del_open_terminal,
                                                    :gap_ins_ext_terminal       => gap_ins_ext_terminal,
                                                    :gap_del_ext_terminal       => gap_del_ext_terminal,
                                                    :evd                        => evd)
                    $logger.info("Importing Fugue profile, #{profile.name}: done")
                  end

                end
              end
            end
          end
        end
      end
    end


    desc "Import Fugue hits"
    task :fugue_hits => [:environment] do

      (10..100).step(10) do |si|
        rep_dir       = File.join(ESST_DIR, "rep#{si}")
        na_esst_dir   = File.join(rep_dir, "na")
        std_esst_dir  = File.join(rep_dir, "std")

        [na_esst_dir, std_esst_dir].each_with_index do |esst_dir, i|
          frts = FileList[esst_dir + "/*.frt"]
          frts.each do |frt|
            sunid           = File.basename(frt, ".frt")
            profile_class   = (i == 0 ? NaProfile : StdProfile)
            fugue_hit_class = (i == 0 ? NaFugueHit : StdFugueHit)
            profile         = profile_class.find_by_name(sunid)
            scop            = Scop.find_by_sunid(sunid)

            IO.foreach(frt) do |line|
              case line.chomp!
              when /^\s*$/ then next
              when /^#/ then next
              when /\s+(.{19})\s+(\S+.*)$/ # d2dpia1 d.240.1....  115   419 448   34.24 1.0E+03   35.19 1.0E+03 1.0E+03 0
                name = $1.strip[0..6]
                slen, raws, rvn, zscore, pvz, zori, evp, evf, al = $2.strip.split(/\s+/)
                name[0]   = 'd' if name =~ /^g/
                  zscore    = zscore.to_f
                scop_dom  = ScopDomain.find_by_sid(name)
                profile.fugue_hits << fugue_hit_class.create!(:scop_id => scop_dom.id,
                                                              :name => name,
                                                              :raws => raws,
                                                              :rvn => rvn,
                                                              :zscore => zscore,
                                                              :zori => zori,
                                                              :fam_tp => (scop_dom.parent.parent.parent.sunid == scop.sunid and zscore >= 6.0 ? true : false),
                                                              :fam_fp => (scop_dom.parent.parent.parent.sunid != scop.sunid and zscore >= 6.0 ? true : false),
                                                              :fam_tn => (scop_dom.parent.parent.parent.sunid != scop.sunid and zscore <  6.0 ? true : false),
                                                              :fam_fn => (scop_dom.parent.parent.parent.sunid == scop.sunid and zscore <  6.0 ? true : false),
                                                              :supfam_tp => (scop_dom.parent.parent.parent.parent.sunid == scop.parent.sunid and zscore >= 6.0 ? true : false),
                                                              :supfam_fp => (scop_dom.parent.parent.parent.parent.sunid != scop.parent.sunid and zscore >= 6.0 ? true : false),
                                                              :supfam_tn => (scop_dom.parent.parent.parent.parent.sunid != scop.parent.sunid and zscore <  6.0 ? true : false),
                                                              :supfam_fn => (scop_dom.parent.parent.parent.parent.sunid == scop.parent.sunid and zscore <  6.0 ? true : false))

                $logger.debug "Importing #{fugue_hit_class}, #{name} with zscore: #{zscore}: done"
              end
            end

            $logger.info "Importing #{fugue_hit_class} for #{sunid}: done"
          end
        end
      end
    end


#    desc "Import Refernce Alignments"
#    task :reference_alignments => [:environment] do
#
#      rep_dir = "/BiO/Research/BIPA/bipa/public/alignments/rep90"
#
#      Dir.new(rep_dir).each do |fam_dir|
#        next if fam_dir =~ /^\./
#
#          FileList[File.join(rep_dir, fam_dir, "*.ref.ali")].each do |f|
#          next unless File.size? f # CAUTIONSome alingments are size 0. Don't know why yet!
#
#          $logger.info "Importing #{f} ..."
#
#          tem_sunid, tgt_sunid = File.basename(f, ".ref.ali").split(/-/)
#          ref_ali = Bio::Alignment::OriginalAlignment.readfiles(Bio::FlatFile.auto(f))
#          ident, align, intgp, count = 0, 0, 0, 0
#
#          ref_ali.each_site do |site|
#            if (site[0] != "-") && (site[1] != "-")
#              align += 1
#              if site[0] == site[1]
#                ident += 1
#              end
#            elsif ((site[0] == "-") && (site[1] != "-")) || ((site[0] != "-") && (site[1] == "-"))
#              intgp += 1
#            end
#            count += 1
#          end
#
#          minl = nil
#          ref_ali.each_seq do |s|
#            l = s.gsub(/-/, '').length
#            if minl.nil?
#              minl = l
#            else
#              minl = l if l < minl
#            end
#          end
#
#          mingl = nil
#          ref_ali.each_seq do |s|
#            gl = s.gsub(/^-+/, '').gsub(/-+$/,'').length
#            if mingl.nil?
#              mingl = gl
#            else
#              mingl = gl if gl < mingl
#            end
#          end
#
#          pid1 = 100 * ident.to_f / (align + intgp)
#          pid2 = 100 * ident.to_f / align
#          pid3 = 100 * ident.to_f / minl
#          pid4 = 100 * ident.to_f / mingl
#
#          family    = Scop.find_by_sunid(fam_dir)
#          alignment = Rep90Alignment.find_by_scop_id(family.id)
#          tem  = Scop.find_by_sunid(tem_sunid)
#          tgt    = Scop.find_by_sunid(tgt_sunid)
#
#          if alignment
#            alignment.reference_alignments << ReferenceAlignment.create!(:template_id => tem.id,
#                                                                         :target_id   => tgt.id,
#                                                                         :pid1        => pid1,
#                                                                         :pid2        => pid2,
#                                                                         :pid3        => pid3,
#                                                                         :pid4        => pid4)
#          else
#            raise "Cannot find alignment AR object for SCOP family, #{fam_dir}"
#          end
#          end
#      end
#    end


    desc "Import Test Alignments"
    task :test_alignments => [:environment] do

      rep_dir = "/BiO/Research/BIPA/bipa/public/alignments/rep90"

      Dir.new(rep_dir).each do |fam_dir|
        next if fam_dir =~ /^\./

        FileList[File.join(rep_dir, fam_dir, "*.bb")].each do |f|
          next unless File.size? f # CAUTIONSome alingments are size 0. Don't know why yet!

          $logger.info "Importing #{f} ..."

          stem = File.basename(f, ".bb")
          tem_sunid, tgt_sunid = stem.match(/(\d+)-(\d+)/)[1..2].to_a
          tem = Scop.find_by_sunid(tem_sunid)
          tgt = Scop.find_by_sunid(tgt_sunid)
          ref_ali = ReferenceAlignment.find_by_template_id_and_target_id(tem.id, tgt.id)
          ali_class = nil
          sp_score = nil
          tc_score = nil

          IO.foreach(f) do |l|
            if l =~ /SP\sscore=\s(\S+)/ then sp_score = $1 end
            if l =~ /TC\sscore=\s(\S+)/ then tc_score = $1 end
          end

          case stem
          when /ndl/  then ali_class = TestNeedleAlignment
          when /clt/  then ali_class = TestClustalwAlignment
          when /std/  then ali_class = TestStdFugueAlignment
          when /na/   then ali_class = TestNaFugueAlignment
          else
            raise "Unknown TestAlignment class!: #{stem}"
          end

          ref_ali.test_alignments << ali_class.create!(:sp => sp_score, :tc => tc_score)
        end

      end
    end


    desc "Import USR Results"
    task :interface_similarities => [:environment] do

      usr_result = "./tmp/interface_similarities.txt"

      if File.exists? usr_result
        system "mysqlimport -h 192.168.1.1 -psemin --local --fields-terminated-by='\\t' --lines-terminated-by='\\n' BIPA_devel #{usr_result}"
        $logger.info "Importing #{usr_result} done."
      else
        $logger.error "could not find #{usr_result}"
        exit 1
      end
    end


    desc "Import Atom Charges and Potentials"
    task :potentials => [:environment] do

      fmanager = ForkManager.new(MAX_FORK)
      aa_pot_files = FileList[File.join(SPICOLI_DIR, "*_aa.pot")].sort
      na_pot_files = FileList[File.join(SPICOLI_DIR, "*_aa.pot")].sort
      pot_files = aa_pot_files + na_pot_files

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        pot_files.each_with_index do |pot_file, i|
          pdb_code = pot_file.match(/(\S{4})\_\S{2}\.pot/)[1]

          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)
            structure = Structure.find_by_pdb_code(pdb_code.upcase)

            if structure.nil?
              $logger.error "!!! Cannot find a structure, #{pdb_code.upcase}"
              ActiveRecord::Base.remove_connection
              exit 1
            end

#            col_names = [ :atom_id,
#                          :formal_charge,
#                          :partial_charge,
#                          :atom_potential,
#                          :asa_potential ]
#            values  = []

            potentials = []

            IO.foreach(pot_file) do |line|
              if line.start_with?('#') or line.blank?
                next
              end

              columns = line.chomp.split(',').map(&:strip)
              model   = structure.models[0]
              chain   = model.chains.find_by_chain_code(columns[0])

              if chain.nil?
                $logger.error "!!! Cannot find a chain, #{columns[0]} of #{pot_file}"
                next
              end

              residue = chain.residues.find_by_residue_code_and_residue_name(columns[1], columns[2])

              if residue.nil?
                $logger.error "!!! Cannot find a residue, #{columns[1]}, #{columns[2]} of #{pot_file}"
                next
              end

              atom = residue.atoms.find_by_atom_name(columns[4])

              if atom.nil?
                $logger.error "!!! Cannot find a atom, #{columns.join(', ')} of #{pot_file}"
                next
              end

              # Uncomment following lines if you want to use import_with_load_data_in_file
#              values << [
#                  atom.id,
#                  columns[5],
#                  columns[6],
#                  columns[7],
#                  columns[8]
#              ]

#              atom.create_potential(:formal_charge   => columns[5],
#                                    :partial_charge  => columns[6],
#                                    :atom_potential  => columns[7],
#                                    :asa_potential   => columns[8])

              potentials << Potential.new(:atom_id        => atom,
                                          :formal_charge  => columns[5],
                                          :partial_charge => columns[6],
                                          :unbound_asa    => columns[7],
                                          :atom_potential => columns[8],
                                          :asa_potential  => columns[9])
            end

            #Potential.import(potentials, :validate => false)
            Potential.import(potentials)
            #Potential.import_with_load_data_infile(col_names, values, :local => false)
            ActiveRecord::Base.remove_connection
            $logger.info ">>> Importing #{pot_file} done."
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end

  end
end
