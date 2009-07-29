namespace :bipa do
  namespace :import do

    desc "Import SCOP datasets"
    task :scop => [:environment] do

      hie = Dir[configatron.scop_dir.join('*hie*scop*')][0]
      des = Dir[configatron.scop_dir.join('*des*scop*')][0]

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
      IO.foreach(des) do |line|
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
      IO.readlines(hie).each_with_index do |line, i|
        next if line =~ /^#/ || line.blank?

        self_sunid, parent_sunid, children_sunids = line.chomp.split(/\t/)
        current_scop = Scop.factory_create!(scop_des[self_sunid])

        unless self_sunid.to_i == 0
          parent_scop = Scop.find_by_sunid(parent_sunid)
          current_scop.move_to_child_of(parent_scop)
        end
      end
      $logger.info ">>> Importing SCOP: done"
    end


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

      fm    = ForkManager.new(configatron.max_fork)
      pdbs  = Dir[configatron.pdb_dir.join("*.pdb").to_s].sort

      fm.manage do
        config = ActiveRecord::Base.remove_connection

        pdbs.each do |pdb|
          fm.fork do
            ActiveRecord::Base.establish_connection(config)

            pdb_code  = File.basename(pdb, ".pdb")
            bio_pdb   = Bio::PDB.new(IO.read(pdb))

            # Parse molecule and chain information. Very dirty... it needs refactoring!
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

            structure = Structure.create!(
              :pdb_code       => bio_pdb.entry_id,
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
            atoms = []

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
                  $logger.warn "!!! #{bio_residue} is a unknown type of standard residue!"
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
            $logger.info ">>> Importing #{pdb}: done"

            # Associate residues with SCOP domains
            domains = ScopDomain.find_all_by_pdb_code(pdb_code)

            if domains.empty?
              $logger.warn "!!! No SCOP domains for #{pdb_code} (#{i+1}/#{pdbs.size})"
            else
              domains.each do |domain|
                structure.models.first.residues.each do |residue|
                  if domain.include? residue
                    residue.domain = domain
                    residue.save!
                  end
                end
              end
              $logger.info ">>> Associating SCOP domains with #{pdb_code} (#{i+1}/#{pdbs.size}): done"
            end

            ActiveRecord::Base.remove_connection
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


    desc "Import NACCESS results into BIPA"
    task :naccess => [:environment] do

      fm    = ForkManager.new(configatron.max_fork)
      pdbs  = Structure.all.map(&:pdb_code).map(&:downcase)

      fm.manage do
        config = ActiveRecord::Base.remove_connection

        pdbs.each do |pdb|
          fm.fork do
            ActiveRecord::Base.establish_connection(config)

            structure           = Structure.find_by_pdb_code(pdb.upcase)
            bound_asa_file      = configatron.naccess_dir.join("#{pdb}_co.asa")
            unbound_aa_asa_file = configatron.naccess_dir.join("#{pdb}_aa.asa")
            unbound_na_asa_file = configatron.naccess_dir.join("#{pdb}_na.asa")

            if (!File.size?(bound_asa_file)       ||
                !File.size?(unbound_aa_asa_file)  ||
                !File.size?(unbound_na_asa_file))
              $logger.warn "!!! Skipped #{pdb}: no NACCESS result file"
              structure.no_naccess = true
              structure.save!
              ActiveRecord::Base.remove_connection
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
                values << [
                  atom.id,
                  unbound_aa_atom_asa[atom.atom_code],
                  bound_atom_asa[atom.atom_code],
                  unbound_aa_atom_asa[atom.atom_code] - bound_atom_asa[atom.atom_code],
                  atom_radius[atom.atom_code]
                ]
              end
            end

            Naccess.import(columns, values)
            ActiveRecord::Base.remove_connection
            $logger.info ">>> Importing #{pdb}.asa: done (#{i + 1}/#{pdbs.size})"
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


    desc "Import DSSP results to BIPA"
    task :dssp => [:environment] do

      fm    = ForkManager.new(configatron.max_fork)
      pdbs  = Structure.all.map(&:pdb_code).map(&:downcase)

      fm.manage do
        config = ActiveRecord::Base.remove_connection

        pdbs.each do |pdb|
          fm.fork do
            ActiveRecord::Base.establish_connection(config)

            structure = Structure.find_by_pdb_code(pdb.upcase)
            dssp_file = configatron.dssp_dir.join("#{pdb}.dssp")

            unless File.size?(dssp_file)
              $logger.warn "!!! Skipped #{pdb}: no DSSP result file"
              structure.no_dssp = true
              structure.save!
              ActiveRecord::Base.remove_connection
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
            $logger.info ">>> Importing #{pdb}.dssp: done"
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


    desc "Import HBPlus results into BIPA"
    task :hbplus => [:environment] do

      fm    = ForkManager.new(configatron.max_fork)
      pdbs  = Structure.all.map(&:pdb_code)

      fm.manage do
        config = ActiveRecord::Base.remove_connection

        pdbs.each do |pdb|
          fm.fork do
            ActiveRecord::Base.establish_connection(config)

            structure   = Structure.find_by_pdb_code(pdb)
            hbplus_file = File.join(configatron.hbplus_dir, "#{pdb.downcase}.hb2")
            bipa_hbonds = Bipa::Hbplus.new(IO.read(hbplus_file)).hbonds
            hbpluses    = []

            if !File.size?(hbplus_file) || bipa_hbonds.empty?
              $logger.warn "!!! Skipped #{pdb}: C-alpha only structure maybe?"
              structure.no_hbplus = true
              structure.save!
              ActiveRecord::Base.remove_connection
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
                  $logger.info ">>> Disulfide bonding cysteine found in #{pdb}"
                end

                acceptor_chain   = structure.models.first.chains.find_by_chain_code(hbond.acceptor.chain_code)
                acceptor_residue = acceptor_chain.residues.find_by_residue_code_and_icode(hbond.acceptor.residue_code, hbond.acceptor.insertion_code)
                acceptor_atom    = acceptor_residue.atoms.find_by_atom_name(hbond.acceptor.atom_name)

                if hbond.acceptor.residue_name =~ /CSS/
                  acceptor_residue.ss = true
                  acceptor_residue.save!
                  $logger.info ">>> Disulfide bonding cysteine found in #{pdb}"
                end
              rescue
                $logger.warn "!!! Cannot find hbplus: #{hbond.donor} <=> #{hbond.acceptor} in #{pdb}"
                next
              else
                if donor_atom && acceptor_atom
                  if Hbplus.exists?(:donor_id => donor_atom.id, :acceptor_id => acceptor_atom.id)
                    $logger.warn "!!! Skipped hbplus: #{donor_atom.id} <=> #{acceptor_atom.id} in #{pdb}"
                    next
                  else
                    hbpluses << Hbplus.new(
                      :donor_id     => donor_atom.id,
                      :acceptor_id  => acceptor_atom.id,
                      :da_distance  => hbond.da_distance,
                      :category     => hbond.category,
                      :gap          => hbond.gap,
                      :ca_distance  => hbond.ca_distance,
                      :dha_angle    => hbond.dha_angle,
                      :ha_distance  => hbond.ha_distance,
                      :haaa_angle   => hbond.haaa_angle,
                      :daaa_angle   => hbond.daaa_angle)
                  end
                end
              end
            end

            Hbplus.import(hbpluses)
            ActiveRecord::Base.remove_connection
            $logger.info ">>> Importing #{pdb.downcase}.hb2: done"
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


    desc "Import hydrogen bonds between protein and nucleic acids"
    task :hbonds => [:environment] do

      fm    = ForkManager.new(configatron.max_fork)
      pdbs  = Structure.untainted.map(&:pdb_code)

      fm.manage do
        config = ActiveRecord::Base.remove_connection

        pdbs.each do |pdb|
          fm.fork do
            ActiveRecord::Base.establish_connection(config)

            columns   = [:donor_id, :acceptor_id, :hbplus_id]
            values    = []
            structure = Structure.find_by_pdb_code(pdb)

            structure.hbplus_as_donor.each do |hbplus|
              if ((hbplus.donor.aa? && hbplus.acceptor.na?) ||
                  (hbplus.donor.na? && hbplus.acceptor.aa?))
                values << [hbplus.donor.id, hbplus.acceptor.id, hbplus.id]
              end
            end

            Hbond.import(columns, values)
            ActiveRecord::Base.remove_connection
            $logger.info ">>> Importing #{values.size} hbonds in #{pdb}: done"
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


    desc "Import Water-mediated hydrogen bonds"
    task :whbonds => [:environment] do

      fm    = ForkManager.new(configatron.max_fork)
      pdbs  = Structure.untainted.map(&:pdb_code)

      fm.manage do
        config = ActiveRecord::Base.remove_connection

        pdbs.each do |pdb|
          fm.fork do
            ActiveRecord::Base.establish_connection(config)

            structure = Structure.find_by_pdb_code(pdb)
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

            Whbond.import(columns, values)
            ActiveRecord::Base.remove_connection
            $logger.info ">>> Importing #{values.size} water-mediated hbonds in #{pdb}: done"
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


    desc "Import van der Waals Contacts"
    task :vdwcontacts => [:environment] do

      fm    = ForkManager.new(configatron.max_fork)
      pdbs  = Structure.all.map(&:pdb_code)

      fm.manage do
        config = ActiveRecord::Base.remove_connection

        pdbs.each do |pdb|
          fm.fork do
            ActiveRecord::Base.establish_connection(config)

            structure = Structure.find_by_pdb_code(pdb)
            kdtree    = Bipa::KDTree.new
            columns   = [:atom_id, :vdw_contacting_atom_id, :distance]
            values    = []

            structure.atoms.each { |a| kdtree.insert(a) }

            aa_atoms = structure.aa_atoms
            na_atoms = structure.na_atoms

            na_atoms.each do |na_atom|
              neighbor_atoms = kdtree.neighbors(na_atom, configatron.max_vdw_distance).map(&:point)
              neighbor_atoms.each do |neighbor_atom|
                if neighbor_atom.aa?
                  dist = na_atom - neighbor_atom
                  values << [neighbor_atom.id, na_atom.id, dist]
#                  if (!Hbond.exists?(:donor_id => neighbor_atom.id, :acceptor_id => na_atom.id) &&
#                      !Hbond.exists?(:donor_id => na_atom.id, :acceptor_id => neighbor_atom.id))
#                    values << [neighbor_atom.id, na_atom.id, dist]
#                  end
                end
              end
            end

            VdwContact.import(columns, values)
            ActiveRecord::Base.remove_connection
            $logger.info ">>> Importing #{values.size} van der Waals contacts in #{pdb}: done"
          end
          ActiveRecord::Base.establish_connection(config)
        end
      end
    end


    desc "Import Domain Interfaces"
    task :domint => [:environment] do

      fm    = ForkManager.new(configatron.max_fork)
      pdbs  = Structure.untainted.map(&:pdb_code)

      fm.manage do
        config = ActiveRecord::Base.remove_connection

        pdbs.each_with_index do |pdb|
          fm.fork do
            ActiveRecord::Base.establish_connection(config)

            domains = ScopDomain.find_all_by_pdb_code(pdb)
            domains.each do |domain|
              %w[dna rna].each do |na|
                iface_found = false

                if domain.send("#{na}_interfaces").size > 0
                  $logger.warn "!!! #{domain.sid} has a already detected #{na} interface"
                  iface_found = true
                  next
                end

                if domain.send("#{na}_binding_interface_residues").size > 0
                  iface = "Domain#{na.camelize}Interface".constantize.new
                  iface.domain = domain
                  iface.residues << domain.send("#{na}_binding_interface_residues")
                  iface.save!
                  iface_found = true
                  $logger.info ">>> #{domain.sid} has a #{na} interface"
                end

                if iface_found == true
                  domain.send("reg_#{na}=", true)
                  domain.save!
                  domain.ancestors.each do |anc|
                    anc.send("reg_#{na}=", true)
                    anc.save!
                  end
                end
              end
            end # domains.each

            ActiveRecord::Base.remove_connection
            $logger.info ">>> Detecting domain interfaces in #{pdb}: done"
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


    desc "Import Chain Interfaces"
    task :chaininterfaces => [:environment] do

      fm    = ForkManager.new(configatron.max_fork)
      pdbs  = Structure.untainted.map(&:pdb_code)

      fm.manage do
        config = ActiveRecord::Base.remove_connection

        pdbs.each do |pdb|
          fm.fork do
            ActiveRecord::Base.establish_connection(config)

            structure = Structure.find_by_pdb_code(pdb)
            structure.chains.each do |chain|
              dna_residues = chain.dna_binding_interface_residues
              rna_residues = chain.rna_binding_interface_residues

              if dna_residues.length > 0
                (chain.dna_interface = ChainDnaInterface.new).residues << dna_residues
                chain.save!
                $logger.info ">>> #{pdb}_#{chain.chain_code} has a DNA interface"
              end

              if rna_residues.length > 0
                (chain.rna_interface = ChainRnaInterface.new).residues << rna_residues
                chain.save!
                $logger.info ">>> #{pdb}_#{chain.chain_code} has a RNA interface"
              end

              if dna_residues.length == 0 && rna_residues.length == 0
                $logger.info ">>> #{pdb}_#{chain.chain_code} has no interface"
              end
            end

            $logger.info ">>> Importing chain interfaces in #{pdb}: done"
            ActiveRecord::Base.remove_connection
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


    desc "Import subfamilies"
    task :subfams => [:environment] do

      %w[dna rna].each do |na|
        sunids = ScopFamily.send("reg_#{na}").map(&:sunid).sort
        config = ActiveRecord::Base.remove_connection

        sunids.forkify(configatron.max_fork) do |sunid|
          ActiveRecord::Base.establish_connection(config)

          family      = ScopFamily.find_by_sunid(sunid)
          fam_dir     = configatron.blastclust_dir.join(na, sunid.to_s)
          subfam_file = fam_dir.join("#{sunid}.cluster")

          IO.foreach(subfam_file) do |line|
            members = line.chomp.split(/\s+/)

            if !members.nil? and !members.empty?
              subfamily = family.send("#{na}_binding_subfamilies").build
              members.each do |member|
                domain = ScopDomain.find_by_sunid(member)
                if domain
                  subfamily.domains << domain
                else
                  $logger.warn "!!! Cannot find SCOP domain, #{member}"
                end
              end
              subfamily.save!
            end
          end

          $logger.info ">>> Importing subfamilies for #{na.upcase}-binding SCOP family, #{sunid}: done"
          ActiveRecord::Base.remove_connection
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


    desc "Import representative alignments for each SCOP Family"
    task :repaligns => [:environment] do

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do
        %w[dna rna].each do |na|
          sunids = ScopFamily.send("reg_#{na}").map(&:sunid).sort
          config = ActiveRecord::Base.remove_connection

          sunids.each do |sunid|
            fm.fork do
              ActiveRecord::Base.establish_connection(config)

              fam    = ScopFamily.find_by_sunid(sunid)
              famdir = configatron.family_dir.join("rep", na, "#{sunid}")
              aligns = Dir[famdir.join("salign*.ali").to_s]

              if aligns.empty?
                $logger.warn "!!! Cannot find alignment files in #{famdir}"
                ActiveRecord::Base.remove_connection
                next
              end

              aligns.each do |align|
                ali = fam.send("#{na}_binding_family_alignments").create
                bio = Bio::FlatFile.auto(align)

                bio.each_entry do |ent|
                  next if ent.seq_type != "P1"

                  dom   = ScopDomain.find_by_sunid(File.basename(ent.entry_id, ".pdb"))
                  dbrs  = dom.aa_residues
                  ffrs  = ent.seq.split("")
                  seq   = ali.sequences.create
                  seq.domain = dom
                  seq.save!

                  di = 0
                  ffrs.each_with_index do |res, fi|
                    break if fi >= dbrs.size
                    col = ali.columns.find_or_create_by_number(fi + 1)
                    pos = seq.positions.create
                    if res == "-"
                      pos.residue_name = res
                    elsif (dbrs[di].one_letter_code == res)
                      pos.residue      = dbrs[di]
                      pos.residue_name = res
                      di += 1
                    else
                      pos.residue_name = 'X'
                      $logger.warn "!!! Mismatch at #{di}, between #{res} and #{dbrs[di].one_letter_code} of #{dom.sid}, #{dom.sunid}"
                    end
                    pos.number = fi + 1
                    pos.column = col
                    pos.save!
                    col.save!
                  end
                  seq.save!
                end
                ali.save!
              end
              $logger.info ">>> Importing alignments for representative sets of #{na.upcase}-binding SCOP family, #{sunid}: done"
              ActiveRecord::Base.remove_connection
            end
          end
          ActiveRecord::Base.establish_connection(config)
        end
      end
    end


    desc "Import subfamily alignments for each SCOP Family"
    task :subaligns => [:environment] do

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do
        %w[dna rna].each do |na|
          sunids = ScopFamily.send("reg_#{na}").map(&:sunid).sort
          config = ActiveRecord::Base.remove_connection

          sunids.each do |sunid|
            fm.fork do
              ActiveRecord::Base.establish_connection(config)

              fam         = ScopFamily.find_by_sunid(sunid)
              famdir      = configatron.family_dir.join("sub", na, sunid.to_s)
              subfamdirs  = Dir[famdir.join("*").to_s]

              subfamdirs.each do |subfamdir|
                align = File.join(subfamdir, "salign.ali")

                if !File.exists? align
                  $logger.warn "!!! Cannot find an alignment file in #{subfamdir}"
                  next
                end

                klass = "#{na.capitalize}BindingSubfamily".constantize
                id    = File.basename(subfamdir)
                ali   = klass.find(id).create_alignment
                bio   = Bio::FlatFile.auto(align)

                bio.each_entry do |ent|
                  next if ent.seq_type != "P1"

                  dom   = ScopDomain.find_by_sunid(File.basename(ent.entry_id, ".pdb"))
                  dbrs  = dom.aa_residues
                  ffrs  = ent.seq.split("")
                  seq   = ali.sequences.create
                  seq.domain = dom
                  seq.save!

                  di = 0
                  ffrs.each_with_index do |res, fi|
                    break if fi >= dbrs.size

                    col = ali.columns.find_or_create_by_number(fi + 1)
                    pos = seq.positions.create
                    if (res == "-")
                      pos.residue_name = res
                    elsif (dbrs[di].one_letter_code == res)
                      pos.residue      = dbrs[di]
                      pos.residue_name = res
                      di += 1
                    else
                      pos.residue_name = 'X'
                      $logger.warn "!!! Mismatch at #{di}, between #{res} and #{dbrs[di].one_letter_code} of #{dom.sid}, #{dom.sunid}"
                    end
                    pos.number = fi + 1
                    pos.column = col
                    pos.save!
                    col.save!
                  end
                  seq.save!
                end
                ali.save!
              end
              $logger.info ">>> Importing subfamily alignments of #{na.upcase}-binding SCOP family, #{sunid}: done"
              ActiveRecord::Base.remove_connection
            end
          end
          ActiveRecord::Base.establish_connection(config)
        end
      end
    end


    desc "Import GO data into 'go_terms' and 'go_relationships' tables"
    task :goterms => [:environment] do

      obo_file  = File.join(configatron.go_dir, "gene_ontology_edit.obo")
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

      goa_pdb_file = File.join(configatron.go_dir, "gene_association.goa_pdb")

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
    task :taxnodes => [:environment] do
      ActiveRecord::Base.connection.execute(
        <<-SQL
          LOAD DATA INFILE "#{Rail.root.join('/public/taxonomy/nodes.dmp')}"
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
    task :taxnames => [:environment] do
      ActiveRecord::Base.connection.execute(
        <<-SQL
          LOAD DATA INFILE "#{Rails.root.join('./public/taxonomy/names.dmp')}"
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

      configatron.rep_pids.each do |si|
        next unless si == 90

        rep_dir       = File.join(configatron.esst_dir, "rep#{si}")
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
      configatron.rep_pids.each do |si|
        rep_dir       = File.join(configatron.esst_dir, "rep#{si}")
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

      configatron.rep_pids.each do |si|
        rep_dir       = File.join(configatron.esst_dir, "rep#{si}")
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


    desc "Import USR Results"
    task :usrs => [:environment] do

      usr       = configatron.usr_res
      host      = Rails.configuration.database_configuration[Rails.env]['host']
      database  = Rails.configuration.database_configuration[Rails.env]['database']

      if File.exists? usr
        system  "mysqlimport -h #{host} " +
                "-psemin --local --fields-terminated-by='\\t' --lines-terminated-by='\\n' " +
                "#{database} #{usr}"
                $logger.info ">>> Importing #{usr} done."
      else
        $logger.error "!!! Could not find #{usr}"
        exit 1
      end
    end


    desc "Import Atom Charges and Potentials"
    task :spicoli => [:environment] do

      aa_pot_files  = Dir[configatron.spicoli_dir.join("*_aa.pot").to_s].sort
      na_pot_files  = Dir[configatron.spicoli_dir.join("*_na.pot").to_s].sort
      pot_files     = aa_pot_files + na_pot_files

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do
        config = ActiveRecord::Base.remove_connection

        pot_files.each_with_index do |pot_file, i|
          pdb_code = pot_file.match(/(\S{4})\_\S{2}\.pot/)[1]

          fm.fork do
            ActiveRecord::Base.establish_connection(config)
            structure = Structure.find_by_pdb_code(pdb_code.upcase)
            if structure.nil?
              $logger.error "!!! Cannot find a structure, #{pdb_code.upcase}"
              ActiveRecord::Base.remove_connection
              exit 1
            end

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

              potentials << Potential.new(:atom_id        => atom,
                                          :formal_charge  => columns[5],
                                          :partial_charge => columns[6],
                                          :unbound_asa    => columns[7],
                                          :atom_potential => columns[8],
                                          :asa_potential  => columns[9])
            end

            Potential.import(potentials)
            ActiveRecord::Base.remove_connection
            $logger.info ">>> Importing #{pot_file} done. (#{i + 1}/#{pot_files.size})"
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end

  end
end
