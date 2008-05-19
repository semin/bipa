require "logger"

$logger = Logger.new(STDOUT)

namespace :bipa do
  namespace :import do

    desc "Import protein-nucleic acid complex PDB files to BIPA tables"
    task :structures => [:environment] do

      # helper methods for Residue and Atom params
      def residue_params(bio_residue)
        {
          :chain_id             => bio_residue.chain.id,
          :residue_code         => bio_residue.residue_id,
          :icode                => bio_residue.iCode.blank? ? nil : bio_residue.iCode,
          :residue_name         => bio_residue.resName.strip,
        }
      end

      def atom_params(bio_atom)
        {
          :residue_id => bio_atom.residue.id,
          :moiety     => bio_atom.moiety,
          :atom_code  => bio_atom.serial,
          :atom_name  => bio_atom.name.strip,
          :altloc     => bio_atom.altLoc.blank? ? nil : bio_atom.altLoc,
          :x          => bio_atom.x,
          :y          => bio_atom.y,
          :z          => bio_atom.z,
          :occupancy  => bio_atom.occupancy,
          :tempfactor => bio_atom.tempFactor,
          :element    => bio_atom.element,
          :charge     => bio_atom.charge.blank? ? nil : bio_atom.charge,
        }
      end

      pdb_files = Dir[PDB_DIR+"/*.pdb"].sort
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        pdb_files.each_with_index do |pdb_file, i|
          tainted = false

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
              :resolution     => bio_pdb.resolution.to_f < EPSILON ? nil : bio_pdb.resolution,
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
                :mol_code   => mol_codes[chain_code] ? mol_codes[chain_code] : nil,
                :molecule   => molecules[chain_code] ? molecules[chain_code] : nil
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
            ActiveRecord::Base.remove_connection
            $logger.info("Importing #{pdb_file}: done (#{i + 1}/#{pdb_files.size})")
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end # task :pdb


    desc "Import SCOP datasets"
    task :scops => [:environment] do

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


    desc "Import NACCESS results into BIPA"
    task :naccess => [:environment] do

      pdb_codes = Structure.find(:all, :select => "pdb_code").map(&:pdb_code).map(&:downcase)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        pdb_codes.each_with_index do |pdb_code, i|

          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)

            structure           = Structure.find_by_pdb_code(pdb_code)
            bound_asa_file      = File.join(NACCESS_DIR, "#{pdb_code}_co.asa")
            unbound_aa_asa_file = File.join(NACCESS_DIR, "#{pdb_code}_aa.asa")
            unbound_na_asa_file = File.join(NACCESS_DIR, "#{pdb_code}_na.asa")
            naccesses           = Array.new

            if (!File.size?(bound_asa_file)       ||
                !File.size?(unbound_aa_asa_file)  ||
                !File.size?(unbound_na_asa_file))
              $logger.warn("SKIP: #{pdb_code} might be an improper PDB file. No NACCESS result found!")
              structure.tainted = true
              structure.save!
              next
            end

            bound_atom_asa      = Bipa::Naccess.new(IO.read(bound_asa_file)).atom_asa
            unbound_aa_atom_asa = Bipa::Naccess.new(IO.read(unbound_aa_asa_file)).atom_asa
            unbound_na_atom_asa = Bipa::Naccess.new(IO.read(unbound_na_asa_file)).atom_asa

            structure.aa_atoms.each do |atom|
              next if !bound_atom_asa.has_key?(atom.atom_code) || !unbound_aa_atom_asa.has_key?(atom.atom_code)
              naccess             = atom.build_naccess
              naccess.bound_asa   = bound_atom_asa[atom.atom_code]
              naccess.unbound_asa = unbound_aa_atom_asa[atom.atom_code]
              naccess.delta_asa   = unbound_aa_atom_asa[atom.atom_code] - bound_atom_asa[atom.atom_code]
              naccesses << naccess
            end

            structure.na_atoms.each do |atom|
              next if !bound_atom_asa.has_key?(atom.atom_code) || !unbound_na_atom_asa.has_key?(atom.atom_code)
              naccess             = atom.build_naccess
              naccess.bound_asa   = bound_atom_asa[atom.atom_code]
              naccess.unbound_asa = unbound_na_atom_asa[atom.atom_code]
              naccess.delta_asa   = unbound_na_atom_asa[atom.atom_code] - bound_atom_asa[atom.atom_code]
              naccesses << naccess
            end

            Naccess.import(naccesses, :validate => false)
            ActiveRecord::Base.remove_connection
            $logger.info("Importing 'naccess' for #{pdb_code}: done (#{i + 1}/#{pdb_codes.size})")
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

            structure = Structure.find_by_pdb_code(pdb_code)
            dssp_file = File.join(DSSP_DIR, "#{pdb_code}.dssp")
            dssps     = Array.new

            if (!File.size?(dssp_file))
              $logger.warn("Skip #{pdb_code} due to missing DSSP result file")
              structure.tainted = true
              structure.save!
              next
            end

            dssp_residues = Bipa::Dssp.new(IO.read(dssp_file)).residues

            structure.models.first.aa_residues.each do |residue|
              key = residue.residue_code.to_s +
                    (residue.icode.blank? ? '' : residue.icode) +
                    residue.chain.chain_code

              dssps << residue.build_dssp(dssp_residues[key].to_hash) if dssp_residues.has_key?(key)
            end

            Dssp.import(dssps, :validate => false)
            ActiveRecord::Base.remove_connection
            $logger.info("Importing 'dssp' for #{pdb_code}: done (#{i + 1}/#{pdb_codes.size})")
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


    desc "Import OpenEYE ZAP results to BIPA"
    task :zap => [:environment] do

      pdb_codes = Structure.find(:all, :select => "pdb_code").map(&:pdb_code).map(&:downcase)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        pdb_codes.each_with_index do |pdb_code, i|

          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)

            structure   = Structure.find_by_pdb_code(pdb_code)
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
              $logger.warn("SKIP: #{pdb_code} due to missing ZAP result")
              structure.tainted = true
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
              $logger.warn("SKIP: #{pdb_code} due to tainted ZAP result")
              structure.tainted = true
              structure.save!
              next
            end

            structure.atoms.each do |atom|
              zaps << atom.build_zap(zap_atoms[atom.atom_code].to_hash) if zap_atoms.has_key?(atom.atom_code)
            end

            Zap.import(zaps, :validate => false)
            ActiveRecord::Base.remove_connection
            $logger.info("Importing 'zap' for #{pdb_code}: done (#{i + 1}/#{pdb_codes.size})")
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


#    desc "Import various hydrophobicity scales to BIPA"
#    task :hydrophobicity => [:environment] do
#    end


    desc "Import van der Waals Contacts"
    task :contacts => [:environment] do

      pdb_codes = Structure.find(:all, :select => "pdb_code").map(&:pdb_code)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        pdb_codes.each_with_index do |pdb_code, i|

          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)

            structure = Structure.find_by_pdb_code(pdb_code)
            kdtree    = Bipa::Kdtree.new
            contacts  = Array.new

            structure.atoms.each { |a| kdtree.insert(a) }

            aa_atoms = structure.aa_atoms
            na_atoms = structure.na_atoms

            na_atoms.each do |na_atom|
              neighbor_atoms = kdtree.neighbors(na_atom, MAX_VDW_DISTANCE).map(&:point)
              neighbor_atoms.each do |neighbor_atom|
                if neighbor_atom.aa?
                  dist = na_atom - neighbor_atom
                  contacts << Contact.new(:atom_id            => neighbor_atom.id,
                                          :contacting_atom_id => na_atom.id,
                                          :distance           => dist)
                end
              end
            end

            Contact.import(contacts, :validate => false)
            ActiveRecord::Base.remove_connection
            $logger.info("Importing 'contacts' in #{pdb_code} : done (#{i + 1}/#{pdb_codes.size})")
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


    desc "Import HBPlus results into BIPA"
    task :hbplus => [:environment] do

      pdb_codes = Structure.find(:all, :select => "pdb_code").map(&:pdb_code).map(&:downcase)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        pdb_codes.each_with_index do |pdb_code, i|

          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)

            structure   = Structure.find_by_pdb_code(pdb_code)
            hbplus_file = File.join(HBPLUS_DIR, "#{pdb_code}.hb2")
            bipa_hbonds = Bipa::Hbplus.new(IO.read(hbplus_file)).hbonds
            hbonds      = Array.new

            if !File.size?(hbplus_file) || bipa_hbonds.empty?
              $logger.warn("Skip #{pdb_code} might be a C-alpha only structure. No HBPLUS results are found!")
              structure.tainted = true
              structure.save!
              next
            end

            bipa_hbonds.each do |hbond|
              begin
                donor_atom =
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
                $logger.warn("Cannot find hbonds: #{hbond.donor} <=> #{hbond.acceptor} in #{pdb_code}")
                next
              else
                if donor_atom && acceptor_atom
                  if Hbplus.exists?(:donor_id => donor_atom.id, :acceptor_id => acceptor_atom.id)
                    #$logger.warn("Skip hbond: #{donor_atom.id} <=> #{acceptor_atom.id} in #{pdb_code}")
                    next
                  else
                    hbplus << Hbplus.new(:donor_id     => donor_atom.id,
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

            Hbplus.import(hbplus, :validate => false) unless hbonds.empty?
            ActiveRecord::Base.remove_connection
            $logger.info("Importing 'hbplus' for #{pdb_code}: done (#{i + 1}/#{pdb_codes.size})")
          end # fmanager.fork
        end # pdb_codes.each_with_index
        ActiveRecord::Base.establish_connection(config)
      end # fmanager.manage
    end


    desc "Import hydrogen bonds between protein and nucleic acids"
    task :hbonds => [:environment] do

      pdb_codes = Structure.untainted.find(:all).map(&:pdb_code)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        pdb_codes.each_with_index do |pdb_code, i|

          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)

            structure = Structure.find_by_pdb_code(pdb_code)
            hbonds    = Array.new

            structure.hbplus_as_donor.each do |hbplus|
              if ((hbplus.donor.aa? && hbplus.acceptor.na?) ||
                  (hbplus.donor.na? && hbplus.acceptor.aa?))
                hbonds << Hbond.new(:donor_id    => hbplus.donor,
                                    :acceptor_id => hbplus.acceptor,
                                    :hbplus_id   => hbplus)
              end
            end

            Hbond.import(hbonds, :validate => false) unless hbonds.empty?
            ActiveRecord::Base.remove_connection
            $logger.info("Importing 'hbonds' for #{pdb_code} (#{i + 1}/#{pdb_codes.size}): done")
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


    desc "Import Water-mediated hydrogen bonds"
    task :whbonds => [:environment] do

      require "facets/array"

      pdb_codes = Structure.untainted.find(:all).map(&:pdb_code)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        pdb_codes.each_with_index do |pdb_code, i|

          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)

            structure   = Structure.find_by_pdb_code(pdb_code)
            whbonds     = Array.new

            structure.water_atoms.each do |water|
              water.hbonding_donors.combination(2).each do |atom1, atom2|
                if atom1.aa? && atom2.na?
                  whbonds << Whbond.new(:atom_id            => atom1,
                                        :whbonding_atom_id  => atom2,
                                        :water_atom_id      => water,
                                        :aa_water_hbond_id  => atom1.hbonds_as_donor.find_by_acceptor_id(water),
                                        :na_water_hbond_id  => atom2.hbonds_as_donor.find_by_acceptor_id(water))
                elsif atom1.na? && atom2.aa?
                  whbonds << Whbond.new(:atom_id            => atom2,
                                        :whbonding_atom_id  => atom1,
                                        :water_atom_id      => water,
                                        :aa_water_hbond_id  => atom2.hbonds_as_donor.find_by_acceptor_id(water),
                                        :na_water_hbond_id  => atom1.hbonds_as_donor.find_by_acceptor_id(water))
                end
              end

              water.hbonding_acceptors.combination(2).each do |atom1, atom2|
                if atom1.aa? && atom2.na?
                  whbonds << Whbond.new(:atom_id            => atom1,
                                        :whbonding_atom_id  => atom2,
                                        :water_atom_id      => water,
                                        :aa_water_hbond_id  => atom1.hbonds_as_acceptor.find_by_donor_id(water),
                                        :na_water_hbond_id  => atom2.hbonds_as_acceptor.find_by_donor_id(water))
                elsif atom1.na? && atom2.aa?
                  whbonds << Whbond.new(:atom_id            => atom2,
                                        :whbonding_atom_id  => atom1,
                                        :water_atom_id      => water,
                                        :aa_water_hbond_id  => atom2.hbonds_as_acceptor.find_by_donor_id(water),
                                        :na_water_hbond_id  => atom1.hbonds_as_acceptor.find_by_donor_id(water))
                end
              end

              water.hbonding_donors.each do |atom1|
                water.hbonding_acceptors.each do |atom2|
                  if atom1.aa? && atom2.na?
                    whbonds << Whbond.new(:atom_id            => atom1,
                                          :whbonding_atom_id  => atom2,
                                          :water_atom_id      => water,
                                          :aa_water_hbond_id  => atom1.hbonds_as_donor.find_by_acceptor_id(water),
                                          :na_water_hbond_id  => atom2.hbonds_as_acceptor.find_by_donor_id(water))
                  elsif atom1.na? && atom2.aa?
                    whbonds << Whbond.new(:atom_id            => atom2,
                                          :whbonding_atom_id  => atom1,
                                          :water_atom_id      => water,
                                          :aa_water_hbond_id  => atom2.hbonds_as_acceptor.find_by_donor_id(water),
                                          :na_water_hbond_id  => atom1.hbonds_as_donor.find_by_acceptor_id(water))
                  end
                end
              end
            end

            Whbond.import(whbonds, :validate => false) unless whbonds.empty?
            ActiveRecord::Base.remove_connection
            $logger.info("Importing 'whbonds' for #{pdb_code} (#{i + 1}/#{pdb_codes.size}): done")
          end # fmanager.fork
        end # pdb_codes.each_with_index
        ActiveRecord::Base.establish_connection(config)
      end # fmanager.manage
    end


    desc "Import Domain Interfaces"
    task :domain_interfaces => [:environment] do

      pdb_codes = Structure.untainted.find(:all).map(&:pdb_code)
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
                  $logger.info("#{domain.sid} has a already detected #{na} interface")
                  iface_found = true
                  next
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
            ActiveRecord::Base.remove_connection
            $logger.info("Extracting domain interfaces from #{pdb_code} (#{i + 1}/#{pdb_codes.size}): done")
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

      sunids    = ScopFamily.registered.find(:all, :select => "sunid").map(&:sunid)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        sunids.each_with_index do |sunid, i|

          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)

            family      = ScopFamily.find_by_sunid(sunid)
            family_dir  = File.join(BLASTCLUST_DIR, "#{sunid}")

            (10..100).step(10) do |si|
              subfamily_file = File.join(family_dir, sunid.to_s + '.cluster' + si.to_s)

              IO.readlines(subfamily_file).each do |line|
                subfamily = "Rep#{si}Subfamily".constantize.new

                members = line.split(/\s+/)
                members.each do |member|
                  domain = ScopDomain.find_by_sunid(member)
                  subfamily.domains << domain
                end

                subfamily.family = family
                subfamily.save!

                $logger.info("Rep#{si}Subfamily (#{subfamily.id}): created")
              end
            end
            ActiveRecord::Base.remove_connection
            $logger.info("Importing subfamilies for #{sunid} : done (#{i + 1}/#{sunids.size})")
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


    desc "Import Full & Representative Alignments for each SCOP Family"
    task :full_alignments => [:environment] do

      sunids    = ScopFamily.registered.find(:all, :select => "sunid").map(&:sunid)
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

            alignment = family.send("create_full_alignment")
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
                  if (db_residues[pos].one_letter_code == res)
                    position.residue      = db_residues[pos]
                    position.residue_name = res
                    position.number       = fi + 1
                    position.column       = column
                    position.save!
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

              alignment = family.send("create_rep#{si}_alignment")
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


    desc "Import GO data into 'go_terms' and 'go_relationships' tables"
    task :go_terms => [:environment] do

      obo_file  = File.join(GO_DIR, "gene_ontology_edit.obo")
      obo_obj   = Bipa::Obo.new(IO.read(obo_file))

      obo_obj.terms.each do |go_id, term|
        term_ar = GoTerm.find_by_go_id(go_id)
        if term_ar.nil?
          GoTerm.create!(term.to_hash)
          $logger.info("Importing #{go_id} into 'go_terms': done")
        end
      end

      obo_obj.relationships.each do |go_id, relationships|
        source = GoTerm.find_by_go_id(go_id)

        relationships.each do |relationship|
          target = GoTerm.find_by_go_id(relationship.target_id)

          if relationship.type == "is_a"
            GoIsA.create!(:source_id => source.id,
                          :target_id => target.id)

            $logger.info("Importing #{go_id} 'is_a' #{relationship.target_id} into 'go_relationships': done")
          elsif relationship.type == "part_of"
            GoPartOf.create!(:source_id => source.id,
                             :target_id => target.id)

            $logger.info("Importing #{go_id} 'part_of' #{relationship.target_id} into 'go_relationships': done")
          elsif relationship.type == "regulates"
            GoRegulates.create!(:source_id => source.id,
                                :target_id => target.id)

            $logger.info("Importing #{go_id} 'regulates' #{relationship.target_id} into 'go_relationships': done")
          elsif relationship.type == "positively_regulates"
            GoPositivelyRegulates.create!(:source_id => source.id,
                                          :target_id => target.id)

            $logger.info("Importing #{go_id} 'positively regulates' #{relationship.target_id} into 'go_relationships': done")
          elsif relationship.type == "negatively_regulates"
            GoNegativelyRegulates.create!(:source_id => source.id,
                                          :target_id => target.id)

            $logger.info("Importing #{go_id} 'negatively regulates' #{relationship.target_id} into 'go_relationships': done")
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

        GoaPdb.create!(
          {
            :chain_id   => chain.id,
            :go_term_id => go_term.id
          }.merge!(line_hsh)
        )

        $logger.info("Importing #{pdb_code}, #{chain_code}, #{line_hsh[:go_id]} into 'goa_pdbs' table: done")
      end
    end


    desc "Import NCBI Taxonomy 'nodes.dmp' file into 'taxonomic_nodes' table"
    task :taxonomic_nodes => [:environment] do
      nodes_file = File.join(TAXONOMY_DIR, "nodes.dmp")

      Node = Struct.new(
        :id,
        :parent_id,
        :rank,
        :embl_code,
        :division_id,
        :inherited_div_flag,
        :genetic_code_id,
        :inherited_gc_flag,
        :mitochondrial_genetic_code_id,
        :inherited_mgc_flag,
        :genbank_hidden_flag,
        :hidden_subtree_root,
        :comments
      )

      IO.foreach(nodes_file) do |line|
        next if line =~ /^#/ || line.blank?
        node_struct = Node.new(*line.gsub(/\t\|\n$/,"").split(/\t\|\t/))
        TaxonomicNode.create!(node_struct.to_hash)
      end

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
      name_file = File.join(TAXONOMY_DIR, "names.dmp")

      Name = Struct.new(
        :tax_id,
        :name_txt,
        :unique_name,
        :name_class
      )

      IO.foreach(names_file) do |line|
        next if line =~ /^#/ || line.blank?
        name = Name.new(*line.gsub(/\t\|\n$/,"").split(/\t\|\t/))
        node = TaxonomicNode.find_by_tax_id(name.tax_id)
        node.names.create!(name.to_hash)
      end
    end

  end
end
