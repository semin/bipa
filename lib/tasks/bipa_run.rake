namespace :bipa do
  namespace :run do

    desc "Run HBPLUS on each PDB file"
    task :hbplus => [:environment] do

      refresh_dir configatron.hbplust_dir

      pdb_files = Dir[File.join(configatron.pdb_dir, "*.pdb")]
      fmanager  = ForkManager.new(configatron.max_fork)

      fmanager.manage do

        pdb_files.each_with_index do |pdb_file, i|

          fmanager.fork do
            cwd       = pwd
            pdb_code  = File.basename(pdb_file, ".pdb")
            work_dir  = File.join(configatron.hbplust_dir, pdb_code)

            mkdir_p work_dir
            chdir work_dir

#            # CLEAN
#            File.open(pdb_code + ".clean_stdout", "w") do |log|
#              IO.popen(CLEAN_BIN, "r+") do |pipe|
#                pipe.puts pdb_file
#                log.puts pipe.readlines
#              end
#            end
#            $logger.info("CLEAN: #{pdb_file} (#{i + 1}/#{pdb_files.size}): done")
#
#            # NACCESS
#            new_pdb_file  = pdb_code + ".new"
#            naccess_input = File.exists?(new_pdb_file) ? new_pdb_file : pdb_file
#            naccess_cmd   = "#{NACCESS_BIN} #{naccess_input} -p 1.40 -z 0.05 -r #{NACCESS_VDW} -s #{NACCESS_STD}"
#
#            File.open(pdb_code + ".naccess.log", "w") do |log|
#              IO.popen(naccess_cmd, "r") do |pipe|
#                log.puts pipe.readlines
#              end
#            end
#            $logger.info("NACCESS: #{naccess_input} (#{i + 1}/#{pdb_files.size}): done")
#
#            # HBADD
#            hbadd_cmd = "#{HBADD_BIN} #{naccess_input} #{HET_DICT_FILE}"
#
#            File.open(pdb_code + ".hbadd.log", "w") do |log|
#              IO.popen(hbadd_cmd, "r") do |pipe|
#                log.puts pipe.readlines
#              end
#            end
#            $logger.info("HBADD: #{naccess_input} (#{i + 1}/#{pdb_files.size}): done")
#
#            # HBPLUS
#            if File.exists?(new_pdb_file)
#              hbplus_cmd = "#{HBPLUS_BIN} -x -R -q -f hbplus.rc #{new_pdb_file} #{pdb_file}"
#            else
#              hbplus_cmd = "#{HBPLUS_BIN} -x -R -q -f hbplus.rc #{pdb_file}"
#            end
#
#            File.open(pdb_code + ".hbplus.log", "w") do |log|
#              IO.popen(hbplus_cmd, "r") do |pipe|
#                log.puts pipe.readlines
#              end
#            end
#
#            mv("hbplus.rc", "#{pdb_code}.rc") if File.exists?("hbplus.rc")
#            $logger.info("HBPLUS: #{pdb_file} (#{i + 1}/#{pdb_files.size}): done")

            sh "#{HBPLUS_BIN} -c #{pdb_file} 1>#{pdb_code}.hbplus.log 2>&1"
            move Dir["*"], ".."
            chdir cwd
            rm_rf work_dir

            $logger.info ">>> Running HBPlus on #{pdb_file} (#{i + 1}/#{pdb_files.size}): done"
          end
        end
      end
    end # task :hbplus


    desc "Run NACCESS on each PDB file"
    task :naccess => [:environment] do

      # Run naccess for every protein-nulceic acid complex,
      # 1) protein only,
      # 2) nucleic acid only,
      # 3) and protein-nucleic acid complex

      refresh_dir configatron.naccess_dir

      pdb_files = Dir[File.join(configatron.pdb_dir, "*.pdb")].sort
      fmanager  = ForkManager.new(configatron.max_fork)

      fmanager.manage do

        pdb_files.each_with_index do |pdb_file, i|

          fmanager.fork do
            cwd       = pwd
            pdb_code  = File.basename(pdb_file, ".pdb")
            pdb_obj   = Bio::PDB.new(IO.read(pdb_file))
            work_dir  = File.join(configatron.naccess_dir, pdb_code)

            if (pdb_obj.models.first.aa_chains.empty? ||
                pdb_obj.models.first.na_chains.empty?)
              $logger.warn "!!! SKIP: #{pdb_file} HAS NO AMINO ACID CHAIN OR NUCLEIC ACID CHAIN"
              next
            end

            mkdir(work_dir)
            chdir(work_dir)

            co_pdb_file = "#{pdb_code}_co.pdb"
            File.open(co_pdb_file, "w") do |f|
              f.puts pdb_obj.models.first.aa_chains.to_s
              f.puts pdb_obj.models.first.na_chains.to_s
              f.puts "END\n"
            end

            aa_pdb_file = "#{pdb_code}_aa.pdb"
            File.open(aa_pdb_file, "w") do |f|
              f.puts pdb_obj.models.first.aa_chains.to_s
              f.puts "END\n"
            end

            na_pdb_file = "#{pdb_code}_na.pdb"
            File.open(na_pdb_file, "w") do |f|
              f.puts pdb_obj.models.first.na_chains.to_s
              f.puts "END\n"
            end

            sh "#{NACCESS_BIN} #{co_pdb_file} -h -r #{NACCESS_VDW} -s #{NACCESS_STD}"
            sh "#{NACCESS_BIN} #{aa_pdb_file} -h -r #{NACCESS_VDW} -s #{NACCESS_STD}"
            sh "#{NACCESS_BIN} #{na_pdb_file} -h -r #{NACCESS_VDW} -s #{NACCESS_STD}"

            cp Dir["#{pdb_code}*"], ".."
            chdir cwd
            rm_r work_dir

            $logger.info ">>> Running NACCESS: #{pdb_file} (#{i + 1}/#{pdb_files.size}): done"
          end
        end
      end
    end


    desc "Run DSSP on each PDB file"
    task :dssp => [:environment] do

      refresh_dir configatron.dssp_dir

      pdb_files = Dir[configatron.pdb_dir.join("*.pdb")]
      fmanager  = ForkManager.new(configatron.max_fork)

      fmanager.manage do
        pdb_files.each_with_index do |pdb_file, i|
          fmanager.fork do
            cwd = pwd
            chdir configatron.dssp_dir
            pdb_code = File.basename(pdb_file, '.pdb')
            system "#{configatron.dssp_bin} #{pdb_file} 1> #{pdb_code}.dssp 2> #{pdb_code}.dssp.err"
            chdir cwd

            $logger.info ">>> Running DSSP on #{pdb_file} (#{i + 1}/#{pdb_files.size}): done"
          end
        end
      end
    end


    desc "Run OESpicoli and OEZap for unbound state PDB structures"
    task :spicoli => [:environment] do

      refresh_dir(configatron.spicoli_dir) unless configatron.resume

      unbound_pdb_files = Dir[configatron.naccess_dir.join("*a.pdb").to_s]

      fmanager = ForkManager.new(configatron.max_fork)
      fmanager.manage do
        unbound_pdb_files.each_with_index do |file, i|
          basename = File.basename(file, ".pdb")
          pot_file = configatron.spicoli_dir.join("#{basename}.pot")

          if File.exists? pot_file
            $logger.info ">>> Skip, #{file}"
            next
          else
            fmanager.fork do
              system "./lib/calculate_electrostatic_potentials #{file} 1> #{pot_file}"
              $logger.info ">>> Calculating electrostatic potentials for #{file}: done (#{i+1}/#{unbound_pdb_files.size})"
            end
          end
        end
      end
    end


    desc "Run blastclust for each SCOP family"
    task :blastclust => [:environment] do

      refresh_dir(configatron.blastclust_dir) unless configatron.resume

      %w[dna rna].each do |na|
        sunids = ScopFamily.send(:"reg_#{na}").map(&:sunid).sort
        config = ActiveRecord::Base.remove_connection

        sunids.forkify(configatron.max_fork) do |sunid|
          ActiveRecord::Base.establish_connection(config)

          family    = ScopFamily.find_by_sunid(sunid)
          fam_dir   = configatron.blastclust_dir.join(na, "#{sunid}")
          fam_fasta = fam_dir.join("#{sunid}.fa")
          mkdir_p fam_dir

          domains = family.leaves.select(&:"reg_#{na}")
          domains.each do |domain|
            seq = domain.to_sequence
            if (seq.count('X') / seq.length.to_f) > 0.5
              $logger.warn  "!!! Skipped: SCOP domain, #{domain.sunid} has " +
                            "too many unknown residues (more than half)!"
              next
            end

            File.open(fam_fasta, "a") do |f|
              f.puts ">#{domain.sunid}"
              f.puts seq
            end
          end

          if File.size? fam_fasta
            blastclust_cmd =
                      "blastclust " +
                      "-i #{fam_fasta} "+
                      "-o #{fam_dir.join(family.sunid.to_s + '.cluster')} " +
                      "-L .9 " +
                      "-S 100 " +
                      "-a 2 " +
                      "-p T " +
                      "1> #{fam_dir.join('blastclust.stdout')} " +
                      "2> #{fam_dir.join('blastclust.stderr')}"
            system blastclust_cmd
          end

          $logger.info ">>> Clustering #{na.upcase}-binding SCOP family, #{sunid}: done"
          ActiveRecord::Base.remove_connection
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


    namespace :salign do

      desc "Run SALIGN for representative PDB files for each SCOP Family"
      task :repscop => [:environment] do

        %w[dna rna].each do |na|
          sunids = ScopFamily.send("reg_#{na}").map(&:sunid).sort
          config = ActiveRecord::Base.remove_connection

          sunids.forkify(configatron.max_fork) do |sunid|
            ActiveRecord::Base.establish_connection(config)
            cwd       = pwd
            fam_dir   = configatron.family_dir.join("rep", na, sunid.to_s)
            pdb_files = Dir[fam_dir.join("*.pdb").to_s].map { |p| File.basename(p) }

            if pdb_files.size < 2
              $logger.warn "!!! Only #{pdb_files.size} PDB structure detected in #{fam_dir}"
              ActiveRecord::Base.remove_connection
              next
            end

            # single linkage clustering using TM-score
            chdir fam_dir
            clusters = Bipa::Tmalign.single_linkage_clustering(pdb_files.combination(1).to_a)
            clusters.each_with_index do |group, gi|
              if group.size < 2
                $logger.warn "!!! Only #{group.size} PDB structure detected in group, #{gi} in #{fam_dir}"
                next
              end

              if File.exists?(File.join(fam_dir, "salign#{gi}.ali")) and File.exists?(File.join(fam_dir, "salign#{gi}.pap"))
                $logger.warn "!!! Skipped group, #{gi} in #{fam_dir}"
                next
              end

              system "salign #{group.join(' ')} 1>salign#{gi}.stdout 2>salign#{gi}.stderr"
              system "mv salign.ali salign#{gi}.ali"
              system "mv salign.pap salign#{gi}.pap"
              $logger.info ">>> SALIGN with group, #{gi} from representative set of #{na.upcase}-binding SCOP family, #{sunid}: done"
            end
            chdir cwd
            ActiveRecord::Base.remove_connection
          end
          ActiveRecord::Base.establish_connection(config)
        end
      end


      desc "Run SALIGN for each subfamilies of SCOP families"
      task :subscop => [:environment] do

        %w[dna rna].each do |na|
          sunids = ScopFamily.send("reg_#{na}").map(&:sunid).sort
          config = ActiveRecord::Base.remove_connection

          sunids.forkify(configatron.max_fork) do |sunid, i|
            ActiveRecord::Base.establish_connection(config)
            cwd     = pwd
            fam_dir = configatron.family_dir.join("sub", na, sunid.to_s)

            Dir[fam_dir.join("*").to_s].each do |subfam_dir|
              pdb_files = Dir[File.join(subfam_dir, "*.pdb")]

              if pdb_files.size < 2
                $logger.warn "!!! Only #{pdb_files.size} PDB structure detected in #{subfam_dir}"
                next
              end

              if File.exists?(File.join(subfam_dir, "salign.ali")) and File.exists?(File.join(subfam_dir, "salign.pap"))
                $logger.warn "!!! Skipped #{subfam_dir}"
                next
              end

              chdir subfam_dir
              system "salign *.pdb 1>salign.stdout 2>salign.stderr"
              chdir cwd
            end

            $logger.info ">>> SALIGN with subfamilies of #{na.upcase}-binding SCOP family, #{sunid}: done"
            ActiveRecord::Base.remove_connection
          end
          ActiveRecord::Base.establish_connection(config)
        end
      end

    end # namespace :salign


    namespace :baton do

      desc "Run Baton for each SCOP family"
      task :full_scop => [:environment] do

        %w[dna rna].each do |na|
          sunids    = ScopFamily.send("reg_#{na}").map(&:sunid).sort
          full_dir  = File.join(configatron.family_dir, "full", na)
          fmanager  = ForkManager.new(configatron.max_fork)

          fmanager.manage do
            config = ActiveRecord::Base.remove_connection

            sunids.each_with_index do |sunid, i|
              fmanager.fork do
                ActiveRecord::Base.establish_connection(config)
                cwd       = pwd
                fam_dir   = File.join(full_dir, sunid.to_s)
                pdb_list  = Dir[fam_dir + "/*.pdb"].map { |p| p.match(/(\d+)\.pdb$/)[1] }

                if pdb_list.size < 2
                  $logger.warn "!!! Only #{pdb_list.size} PDB structure detected in #{fam_dir}"
                  ActiveRecord::Base.remove_connection
                  next
                end

                chdir fam_dir
                pdb_list_file = "pdb_files.lst"
                File.open(pdb_list_file, "w") { |f| f.puts pdb_list.map { |p| p + ".pdb" }.join("\n") }
                system "Baton -input /BiO/Install/Baton/data/baton.prm.current -features -pdbout -matrixout -list #{pdb_list_file} 1>baton.log 2>&1"

                if !File.exists? "baton.ali"
                  $logger.error "!!! Cannot find Baton result file, baton.ali for #{na}-binding SCOP family, #{sunid}"
                  ActiveRecord::Base.remove_connection
                  exit 1
                end

                chdir cwd
                $logger.info ">>> Baton with full set of #{na.upcase}-binding SCOP family, #{sunid}: done (#{i + 1}/#{sunids.size})"
                ActiveRecord::Base.remove_connection
              end
            end
            ActiveRecord::Base.establish_connection(config)
          end
        end
      end


      desc "Run Baton for representative PDB files for each SCOP Family"
      task :rep_scop => [:environment] do

        %w[dna rna].each do |na|
          sunids    = ScopFamily.send("reg_#{na}").map(&:sunid).sort
          fmanager  = ForkManager.new(configatron.max_fork)

          fmanager.manage do
            config = ActiveRecord::Base.remove_connection

            (10..100).step(10) do |pid|
              sunids.each_with_index do |sunid, i|
                fmanager.fork do
                  ActiveRecord::Base.establish_connection(config)

                  cwd       = pwd
                  fam_dir   = File.join(configatron.family_dir, "nr#{pid}", na, sunid.to_s)
                  pdb_list  = Dir[fam_dir.join("*.pdb")].map { |p| p.match(/(\d+)\.pdb$/)[1] }

                  if pdb_list.size < 2
                    $logger.warn "!!! Only #{pdb_list.size} PDB structure detected in #{fam_dir}"
                    ActiveRecord::Base.remove_connection
                    next
                  end

                  chdir fam_dir
                  pdb_list_file = "pdb_files.lst"
                  File.open(pdb_list_file, "w") { |f| f.puts pdb_list.map { |p| p + ".pdb" }.join("\n") }
                  system "Baton -input /BiO/Install/Baton/data/baton.prm.current -features -pdbout -matrixout -list #{pdb_list_file} 1>baton.log 2>&1"

                  if !File.exists? "baton.ali"
                    $logger.error "!!! Cannot find Baton result file, baton.ali for #{na}-binding SCOP family, #{sunid}"
                    ActiveRecord::Base.remove_connection
                    exit 1
                  end

                  chdir cwd
                  $logger.info ">>> BATON with non-redundant (PID < #{pid}) set of #{na.upcase}-binding SCOP family, #{sunid}: done (#{i + 1}/#{sunids.size})"
                  ActiveRecord::Base.remove_connection
                end
              end
            end
            ActiveRecord::Base.establish_connection(config)
          end
        end
      end


      desc "Run Baton for each subfamilies of SCOP families"
      task :sub_scop => [:environment] do

        %w[dna rna].each do |na|
          sunids    = ScopFamily.send("reg_#{na}").map(&:sunid).sort
          fmanager  = ForkManager.new(configatron.max_fork)

          fmanager.manage do
            config = ActiveRecord::Base.remove_connection

            sunids.each_with_index do |sunid, i|
              fmanager.fork do
                ActiveRecord::Base.establish_connection(config)

                cwd     = pwd
                fam_dir = File.join(configatron.family_dir, "sub", na, sunid.to_s)

                Dir[fam_dir.join("nr*", "*")].each do |subfam_dir|
                  pdb_files = Dir[subfam_dir.join("*.pdb")]

                  if pdb_files.size < 2
                    $logger.warn "!!! Only #{pdb_file.size} PDB structure detected in #{subfam_dir}"
                    next
                  end

                  chdir subfam_dir
                  system "Baton -input /BiO/Install/Baton/data/baton.prm.current -features -pdbout -matrixout *.pdb 1>baton.log 2>&1"
                  chdir cwd
                end

                $logger.info ">>> BATON with subfamily PDB files for #{na}-binding SCOP family, #{sunid}: done (#{i + 1}/#{sunids.size})"
                ActiveRecord::Base.remove_connection
              end
            end
            ActiveRecord::Base.establish_connection(config)
          end
        end
      end

    end # namespace :baton


    desc "Run ZAP for each SCOP Domain PDB file"
    task :zap => [:environment] do

      refresh_dir(configatron.zip_dir) unless configatron.resume

      pdb_codes = Dir[configatron.naccess_dir.join("*_aa.asa")].map { |f| f.match(/(\S{4})_aa/)[1] }.sort
      fmanager  = ForkManager.new(configatron.max_fork)

      fmanager.manage do
        pdb_codes.each_with_index do |pdb_code, i|
          fmanager.fork do
            [pdb_code + "_aa", pdb_code + "_na"].each do |pdb_stem|
              zap_file = configatron.zip_dir(pdb_stem + '.zap')
              grd_file = configatron.zip_dir(pdb_stem + '.grd')
              err_file = configatron.zip_dir(pdb_stem + '.err')
              pdb_file = configatron.naccess_dir(pdb_stem + '.pdb')

              if File.size? zap_file
                $logger.warn "Skipped, #{pdb_code}: ZAP results files are already there!"
                next
              end

              system "python ./lib/zap_atompot.py -in #{pdb_file} -calc_type remove_self -atomtable 1> #{zap_file} 2> #{err_file}"
            end
            $logger.info ">>> Running ZAP on #{pdb_code}: done (#{i + 1}/#{pdb_codes.size})"
          end
        end
      end
    end


    namespace :joy do

      desc "Run JOY for representative SCOP family alignments"
      task :rep_alignments => [:environment] do

        %w[dna rna].each do |na|
          cwd = pwd
          fam_dirs = Dir[configatron.family_dir.join("rep", na, "*").to_s]
          fam_dirs.forkify(configatron.max_fork) do |fam_dir|
            ali_files = Dir[File.join(fam_dir, "salign*.ali").to_s]

            if ali_files.nil? or ali_files.size < 1
              $logger.error "!!! Cannot find alignment files in #{fam_dir}"
              next
            end

            chdir fam_dir

            ali_files.each do |ali_file|
              basename      = File.basename(ali_file, ".ali")
              cluster_id    = basename.match(/salign(\d+)/)[1]
              mod_ali_file  = "#{basename}_mod.ali"
              File.open(mod_ali_file, "w") { |f| f.puts IO.read(ali_file).gsub(/\.pdb/, "") }
              system "joy #{mod_ali_file} 1>joy#{cluster_id}.stdout 2>joy#{cluster_id}.stderr"
            end

            chdir cwd
            $logger.info ">>> JOY with alignments in #{fam_dir}: done"
          end
        end
      end


      desc "Run JOY for SCOP subfamily alignments"
      task :sub_alignments => [:environment] do
        %w[dna rna].each do |na|
          cwd         = pwd
          subfam_dirs = Dir[configatron.family_dir.join("sub", na, "*", "red", "*").to_s]
          subfam_dirs.forkify(configatron.max_fork) do |subfam_dir|
            ali_file = File.join(subfam_dir, "salign.ali")

            if !File.exists? ali_file
              $logger.error "!!! Cannot find an alignment file in #{subfam_dir}"
              next
            end

            chdir subfam_dir

            basename      = File.basename(ali_file, ".ali")
            mod_ali_file  = "#{basename}_mod.ali"
            File.open(mod_ali_file, "w") { |f| f.puts IO.read(ali_file).gsub(/\.pdb/, "") }
            system "joy #{mod_ali_file} 1>joy.stdout 2>joy.stderr"
            chdir cwd
            $logger.info ">>> JOY with an alignment in #{subfam_dir}: done"
          end
        end
      end

    end # namespace :joy


    desc "Run fugueprf for each profiles of all non-redundant sets of SCOP families"
    task :fugueprf => [:environment] do

      (20..100).step(20) do |si|
        next if si != 80

        %w[dna rna].each do |na|
          %w[16 32 std].each do |env|
            est_dir = File.join(configatron.esst_dir, "rep#{si}", "#{na}#{env}")
            seq     = ASTRAL40
            cwd     = pwd
            chdir dir

            Dir[est_dir + "/*.fug"].each_with_index do |fug, i|
              sunid = File.basename(fug, ".fug")
              $logger.info "fugueprf: #{sunid} ..."
              system "fugueprf -seq #{seq} -prf #{fug} -o #{sunid}.hit > #{sunid}.frt"
            end
            chdir cwd
          end
        end
      end
    end


    desc "Run fugueali for a selected set of hits from fugueprf"
    task :fugueali => [:environment] do

      (20..100).step(20) do |si|
        next if si != 80

        %w[dna rna].each do |na|
          %w[16 32 std].each do |env|
            cwd     = pwd
            est_dir = File.join(configatron.esst_dir, "rep#{si}", "#{na}#{env}")
            master  = nil

            chdir est_dir

            Dir["./*.tem"].each do |tem_file|
              fam_sunid = File.basename(tem_file, "*.tem")
              fam_ali   = Scop.find_by_sunid(fam_sunid).send(:"rep#{si}_alignment")
              domains   = fam_ali.sequences.map(&:domain)

              domains.each_with_index do |dom, di|
                sunid = dom.sunid

                if di == 0
                  master = sunid

                  File.open("#{sunid}.tem", "w") do |file|
                    res_tem = []
                    sec_tem = []
                    acc_tem = []

                    dna_tem = []
                    rna_tem = []

                    hbond_dna_tem   = []
                    whbond_dna_tem  = []
                    vdw_dna_tem     = []

                    hbond_rna_tem   = []
                    whbond_rna_tem  = []
                    vdw_rna_tem     = []

                    dom.residues.each_with_index do |res, ri|
                      if ri != 0 and ri % 75 == 0
                        res_tem << "\n"
                        sec_tem << "\n"
                        acc_tem << "\n"

                        dna_tem << "\n"
                        rna_tem << "\n"

                        hbond_dna_tem   << "\n"
                        whbond_dna_tem  << "\n"
                        vdw_dna_tem     << "\n"

                        hbond_rna_tem   << "\n"
                        whbond_rna_tem  << "\n"
                        vdw_rna_tem     << "\n"
                      end

                      res_tem << res.one_letter_code
                      sec_tem << case
                      when res.alpha_helix? || res.three10_helix? then  "H"
                      when res.beta_sheet? then  "E"
                      when res.positive_phi? then  "P"
                      else "C"
                      end
                      acc_tem << case
                      when res.on_surface? then  "T"
                      else "F"
                      end

                      if res.hbonding_dna?
                        hbond_dna_tem << "T"
                      else
                        hbond_dna_tem << "F"
                      end

                      if res.whbonding_dna?
                        whbond_dna_tem << "T"
                      else
                        whbond_dna_tem << "F"
                      end

                      if res.vdw_contacting_dna?
                        vdw_dna_tem << "T"
                      else
                        vdw_dna_tem << "F"
                      end

                      if res.binding_dna?
                        dna_tem << "T"
                      else
                        dna_tem << "F"
                      end

                      if res.hbonding_rna?
                        hbond_rna_tem << "T"
                      else
                        hbond_rna_tem << "F"
                      end

                      if res.whbonding_rna?
                        whbond_rna_tem << "T"
                      else
                        whbond_rna_tem << "F"
                      end

                      if res.vdw_contacting_rna?
                        vdw_rna_tem << "T"
                      else
                        vdw_rna_tem << "F"
                      end

                      if res.binding_rna?
                        rna_tem << "T"
                      else
                        rna_tem << "F"
                      end
                    end

                    file.puts ">P1;#{sunid}"
                    file.puts "sequence"
                    file.puts res_tem.join + "*"

                    file.puts ">P1;#{sunid}"
                    file.puts "secondary structure and phi angle"
                    file.puts sec_tem.join + "*"

                    file.puts ">P1;#{sunid}"
                    file.puts "solvent accessibility"
                    file.puts acc_tem.join + "*"

                    file.puts ">P1;#{sunid}"
                    file.puts "hydrogen bond to DNA"
                    file.puts hbond_dna_tem.join + "*"

                    file.puts ">P1;#{sunid}"
                    file.puts "water-mediated hydrogen bond to DNA"
                    file.puts whbond_dna_tem.join + "*"

                    file.puts ">P1;#{sunid}"
                    file.puts "vdw contact to DNA"
                    file.puts vdw_dna_tem.join + "*"

                    file.puts ">P1;#{sunid}"
                    file.puts "DNA interface"
                    file.puts dna_tem.join + "*"

                    file.puts ">P1;#{sunid}"
                    file.puts "hydrogen bond to RNA"
                    file.puts hbond_rna_tem.join + "*"

                    file.puts ">P1;#{sunid}"
                    file.puts "water-mediated hydrogen bond to RNA"
                    file.puts whbond_rna_tem.join + "*"

                    file.puts ">P1;#{sunid}"
                    file.puts "vdw contact to RNA"
                    file.puts vdw_rna_tem.join + "*"

                    file.puts ">P1;#{sunid}"
                    file.puts "RNA interface"
                    file.puts rna_tem.join + "*"
                  end

                  # Run melody for generating Fugue profile
                  system "melody -t #{sunid}.tem -c classdef.na.dat -s allmat.na.log.dat -y -o #{sunid}.na.fug"
                  system "melody -t #{sunid}.tem -c classdef.std.dat -s allmat.std.log.dat -y -o #{sunid}.std.fug"
                else # for other entries
                  File.open("#{temp}-#{sunid}.ref.ali", "w") do |f|
                    file.puts ">P1;#{temp}"
                    file.puts "sequence"
                    file.puts  fam_ali.sequnces.select { |s| s.domain.sunid == temp }.positions.map(&:residue_name).join + "*"

                    file.puts ">P1;#{sunid}"
                    file.puts "sequence"
                    file.puts  fam_ali.sequnces.select { |s| s.domain.sunid == sunid }.positions.map(&:residue_name).join + "*"
                  end

                  system "mview -in pir -out msf #{temp}-#{sunid}.ref.ali > #{temp}-#{sunid}.ref.msf"

                  system "fugueali -seq #{sunid}.ali -prf #{temp}.na.fug -y -o #{temp}-#{sunid}.na.fug.ali"
                  system "mview -in pir -out msf #{temp}-#{sunid}.na.fug.ali > #{temp}-#{sunid}.na.fug.msf"
                  system "#{configatron.baliscore_bin} #{temp}-#{sunid}.ref.msf #{temp}-#{sunid}.na.fug.msf > #{temp}-#{sunid}.na.fug.bb"

                  system "fugueali -seq #{sunid}.ali -prf #{temp}.std.fug -y -o #{temp}-#{sunid}.std.fug.ali"
                  system "mview -in pir -out msf #{temp}-#{sunid}.std.fug.ali > #{temp}-#{sunid}.std.fug.msf"
                  system "#{configatron.baliscore_bin} #{temp}-#{sunid}.ref.msf #{temp}-#{sunid}.std.fug.msf > #{temp}-#{sunid}.std.fug.bb"

                  system "needle -asequence #{temp}.ali -bsequence #{sunid}.ali -aformat msf -outfile #{temp}-#{sunid}.ndl.msf -gapopen 10.0 -gapextend 0.5"
                  system "#{configatron.baliscore_bin} #{temp}-#{sunid}.ref.msf #{temp}-#{sunid}.ndl.msf > #{temp}-#{sunid}.ndl.bb"

                  system "cat #{temp}.ali #{sunid}.ali > #{temp}-#{sunid}.ali"
                  system "clustalw2 -INFILE=#{temp}-#{sunid}.ali -ALIGN -OUTFILE=#{temp}-#{sunid}.clt.msf -OUTPUT=GCG"
                  system "#{configatron.baliscore_bin} #{temp}-#{sunid}.ref.msf #{temp}-#{sunid}.clt.msf > #{temp}-#{sunid}.clt.bb"
                end
              end
            end
          end
          chdir cwd
        end
      end
    end


    desc "Calculate USR similarities using pre-calculated descriptors"
    task :usrc => [:environment] do
      system "#{configatron.usr_bin} < #{configatron.usr_des} > #{configatron.usr_res}"
      $logger.info ">>> Running usr done."
    end

  end
end
