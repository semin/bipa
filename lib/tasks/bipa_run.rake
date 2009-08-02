namespace :bipa do
  namespace :run do

    desc "Run HBPLUS on each PDB file"
    task :hbplus => [:environment] do

      refresh_dir configatron.hbplust_dir

      fm    = ForkManager.new(configatron.max_fork)
      pdbs  = Dir[File.join(configatron.pdb_dir, "*.pdb")]

      fm.manage do
        pdbs.each_with_index do |pdb, i|
          fm.fork do
            cwd       = pwd
            pdb_code  = File.basename(pdb, ".pdb")
            work_dir  = File.join(configatron.hbplust_dir, pdb_code)

            mkdir_p work_dir
            chdir work_dir

#            # CLEAN
#            File.open(pdb_code + ".clean_stdout", "w") do |log|
#              IO.popen(CLEAN_BIN, "r+") do |pipe|
#                pipe.puts pdb
#                log.puts pipe.readlines
#              end
#            end
#            $logger.info("CLEAN: #{pdb} (#{i + 1}/#{pdbs.size}): done")
#
#            # NACCESS
#            new_pdb  = pdb_code + ".new"
#            naccess_input = File.exists?(new_pdb) ? new_pdb : pdb
#            naccess_cmd   = "#{NACCESS_BIN} #{naccess_input} -p 1.40 -z 0.05 -r #{NACCESS_VDW} -s #{NACCESS_STD}"
#
#            File.open(pdb_code + ".naccess.log", "w") do |log|
#              IO.popen(naccess_cmd, "r") do |pipe|
#                log.puts pipe.readlines
#              end
#            end
#            $logger.info("NACCESS: #{naccess_input} (#{i + 1}/#{pdbs.size}): done")
#
#            # HBADD
#            hbadd_cmd = "#{HBADD_BIN} #{naccess_input} #{HET_DICT_FILE}"
#
#            File.open(pdb_code + ".hbadd.log", "w") do |log|
#              IO.popen(hbadd_cmd, "r") do |pipe|
#                log.puts pipe.readlines
#              end
#            end
#            $logger.info("HBADD: #{naccess_input} (#{i + 1}/#{pdbs.size}): done")
#
#            # HBPLUS
#            if File.exists?(new_pdb)
#              hbplus_cmd = "#{HBPLUS_BIN} -x -R -q -f hbplus.rc #{new_pdb} #{pdb}"
#            else
#              hbplus_cmd = "#{HBPLUS_BIN} -x -R -q -f hbplus.rc #{pdb}"
#            end
#
#            File.open(pdb_code + ".hbplus.log", "w") do |log|
#              IO.popen(hbplus_cmd, "r") do |pipe|
#                log.puts pipe.readlines
#              end
#            end
#
#            mv("hbplus.rc", "#{pdb_code}.rc") if File.exists?("hbplus.rc")
#            $logger.info("HBPLUS: #{pdb} (#{i + 1}/#{pdbs.size}): done")

            sh "#{HBPLUS_BIN} -c #{pdb} 1>#{pdb_code}.hbplus.log 2>&1"
            move Dir["*"], ".."
            chdir cwd
            rm_rf work_dir

            $logger.info ">>> Running HBPlus on #{pdb} (#{i + 1}/#{pdbs.size}): done"
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

      fm    = ForkManager.new(configatron.max_fork)
      pdbs  = Dir[File.join(configatron.pdb_dir, "*.pdb")].sort

      fm.manage do
        pdbs.each_with_index do |pdb, i|
          fm.fork do
            cwd       = pwd
            pdb_code  = File.basename(pdb, ".pdb")
            pdb_obj   = Bio::PDB.new(IO.read(pdb))
            work_dir  = File.join(configatron.naccess_dir, pdb_code)

            if (pdb_obj.models.first.aa_chains.empty? ||
                pdb_obj.models.first.na_chains.empty?)
              $logger.warn "!!! SKIP: #{pdb} HAS NO AMINO ACID CHAIN OR NUCLEIC ACID CHAIN"
              next
            end

            mkdir(work_dir)
            chdir(work_dir)

            co_pdb = "#{pdb_code}_co.pdb"
            File.open(co_pdb, "w") do |f|
              f.puts pdb_obj.models.first.aa_chains.to_s
              f.puts pdb_obj.models.first.na_chains.to_s
              f.puts "END\n"
            end

            aa_pdb = "#{pdb_code}_aa.pdb"
            File.open(aa_pdb, "w") do |f|
              f.puts pdb_obj.models.first.aa_chains.to_s
              f.puts "END\n"
            end

            na_pdb = "#{pdb_code}_na.pdb"
            File.open(na_pdb, "w") do |f|
              f.puts pdb_obj.models.first.na_chains.to_s
              f.puts "END\n"
            end

            sh "#{NACCESS_BIN} #{co_pdb} -h -r #{NACCESS_VDW} -s #{NACCESS_STD}"
            sh "#{NACCESS_BIN} #{aa_pdb} -h -r #{NACCESS_VDW} -s #{NACCESS_STD}"
            sh "#{NACCESS_BIN} #{na_pdb} -h -r #{NACCESS_VDW} -s #{NACCESS_STD}"

            cp Dir["#{pdb_code}*"], ".."
            chdir cwd
            rm_r work_dir

            $logger.info ">>> Running NACCESS: #{pdb} (#{i + 1}/#{pdbs.size}): done"
          end
        end
      end
    end


    desc "Run DSSP on each PDB file"
    task :dssp => [:environment] do

      refresh_dir configatron.dssp_dir

      fm    = ForkManager.new(configatron.max_fork)
      pdbs  = Dir[configatron.pdb_dir.join("*.pdb")]

      fm.manage do
        pdbs.each_with_index do |pdb, i|
          fm.fork do
            cwd = pwd
            chdir configatron.dssp_dir
            pdb_code = File.basename(pdb, '.pdb')
            system "#{configatron.dssp_bin} #{pdb} 1> #{pdb_code}.dssp 2> #{pdb_code}.dssp.err"
            chdir cwd
            $logger.info ">>> Running DSSP on #{pdb} (#{i + 1}/#{pdbs.size}): done"
          end
        end
      end
    end


    desc "Run OESpicoli and OEZap for unbound state PDB structures"
    task :spicoli => [:environment] do

      refresh_dir(configatron.spicoli_dir) unless configatron.resume

      fm    = ForkManager.new(configatron.max_fork)
      pdbs  = Dir[configatron.naccess_dir.join("*a.pdb").to_s]

      fm.manage do
        pdbs.each_with_index do |pdb, i|
          bsn = File.basename(pdb, ".pdb")
          pot = configatron.spicoli_dir.join("#{bsn}.pot")

          if File.exists? pot
            $logger.info ">>> Skip, #{pdb}"
            next
          else
            fm.fork do
              system "./lib/calculate_electrostatic_potentials #{pdb} 1> #{pot}"
              $logger.info ">>> Calculating electrostatic potentials for #{pdb}: done (#{i+1}/#{pdbs.size})"
            end
          end
        end
      end
    end


    desc "Run blastclust for each SCOP family"
    task :blastclust => [:environment] do

      refresh_dir(configatron.blastclust_dir) unless configatron.resume

      fm = ForkManager.new(configatron.max_fork)

      fm.manage do
        %w[dna rna].each do |na|
          ScopFamily.send(:"reg_#{na}").find_each do |fam|
            sunid     = fam.sunid
            fam_dir   = configatron.blastclust_dir.join(na, "#{sunid}")
            fam_fasta = fam_dir.join("#{sunid}.fa")

            mkdir_p fam_dir

            doms = fam.leaves.select(&:"reg_#{na}")
            doms.each do |dom|
              seq = dom.to_sequence
              if (seq.count('X') / seq.length.to_f) > 0.5
                $logger.warn  "!!! Skipped: SCOP domain, #{dom.sunid} has " +
                              "too many unknown residues (more than half)!"
                next
              end

              File.open(fam_fasta, "a") do |f|
                f.puts ">#{dom.sunid}"
                f.puts seq
              end
            end

            ActiveRecord::Base.remove_connection
            fm.fork do
              if File.size? fam_fasta
                blastclust_cmd =  "blastclust " +
                                  "-i #{fam_fasta} "+
                                  "-o #{fam_dir.join(sunid.to_s + '.cluster')} " +
                                  "-L .9 " +
                                  "-S 100 " +
                                  "-a 2 " +
                                  "-p T " +
                                  "1> #{fam_dir.join('blastclust.stdout')} " +
                                  "2> #{fam_dir.join('blastclust.stderr')}"

                system blastclust_cmd
              end
            end
            ActiveRecord::Base.establish_connection
            $logger.info ">>> Clustering #{na.upcase}-binding SCOP family, #{sunid}: done"
          end
        end
      end
    end


    namespace :salign do

      desc "Run SALIGN for representative PDB files for each SCOP Family"
      task :repscop => [:environment] do

        fm = ForkManager.new(configatron.max_fork)
        fm.manage do
          %w[dna rna].each do |na|
            sunids = ScopFamily.send("reg_#{na}").map(&:sunid).sort
            config = ActiveRecord::Base.remove_connection

            sunids.each do |sunid|
              cwd     = pwd
              famdir  = configatron.family_dir.join("rep", na, sunid.to_s)
              pdbs    = Dir[famdir.join("*.pdb").to_s].map { |p| File.basename(p) }

              if pdbs.size < 2
                $logger.warn "!!! Only #{pdbs.size} PDB structure detected in #{famdir}"
                next
              end

              chdir famdir

              # single linkage clustering using TM-score
              clsts = Bipa::Tmalign.single_linkage_clustering(pdbs.combination(1).to_a)
              clsts.each_with_index do |grp, gi|
                if grp.size < 2
                  $logger.warn "!!! Only #{grp.size} PDB structure detected in group, #{gi} in #{famdir}"
                  next
                end

                if File.size?(famdir.join("salign#{gi}.ali")) and File.size?(famdir.join("salign#{gi}.pap"))
                  $logger.warn "!!! Skipped group, #{gi} in #{famdir}"
                  next
                end

                fm.fork do
                  system "salign #{grp.join(' ')} 1>salign#{gi}.stdout 2>salign#{gi}.stderr"
                  system "mv salign.ali salign#{gi}.ali"
                  system "mv salign.pap salign#{gi}.pap"
                  $logger.info ">>> SALIGN with group, #{gi} from representative set of #{na.upcase}-binding SCOP family, #{sunid}: done"
                end
              end
              chdir cwd
            end
            ActiveRecord::Base.establish_connection(config)
          end
        end
      end


      desc "Run SALIGN for each subfamilies of SCOP families"
      task :subscop => [:environment] do

        fm = ForkManager.new(configatron.max_fork)
        fm.manage do
          %w[dna rna].each do |na|
            sunids = ScopFamily.send("reg_#{na}").map(&:sunid).sort
            config = ActiveRecord::Base.remove_connection

            sunids.each do |sunid|
              cwd     = pwd
              famdir  = configatron.family_dir.join("sub", na, sunid.to_s)

              Dir[famdir.join("*").to_s].each do |subfamdir|
                pdbs = Dir[File.join(subfamdir, "*.pdb")]

                if pdbs.size < 2
                  $logger.warn "!!! Only #{pdbs.size} PDB structure detected in #{subfamdir}"
                  next
                end

                if File.size?(File.join(subfamdir, "salign.ali")) and File.size?(File.join(subfamdir, "salign.pap"))
                  $logger.warn "!!! Skipped #{subfamdir}"
                  next
                end

                chdir subfamdir

                fm.fork do
                  system "salign *.pdb 1>salign.stdout 2>salign.stderr"
                end

                chdir cwd
              end
              $logger.info ">>> SALIGN with subfamilies of #{na.upcase}-binding SCOP family, #{sunid}: done"
            end
            ActiveRecord::Base.establish_connection(config)
          end
        end
      end

    end # namespace :salign


    namespace :baton do

      desc "Run Baton for each SCOP family"
      task :full_scop => [:environment] do

        %w[dna rna].each do |na|
          sunids    = ScopFamily.send("reg_#{na}").map(&:sunid).sort
          full_dir  = File.join(configatron.family_dir, "full", na)
          fm  = ForkManager.new(configatron.max_fork)

          fm.manage do
            config = ActiveRecord::Base.remove_connection

            sunids.each_with_index do |sunid, i|
              fm.fork do
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
                pdb_list_file = "pdbfiles.lst"
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
          fm  = ForkManager.new(configatron.max_fork)

          fm.manage do
            config = ActiveRecord::Base.remove_connection

            (10..100).step(10) do |pid|
              sunids.each_with_index do |sunid, i|
                fm.fork do
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
                  pdb_list_file = "pdbfiles.lst"
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
          fm  = ForkManager.new(configatron.max_fork)

          fm.manage do
            config = ActiveRecord::Base.remove_connection

            sunids.each_with_index do |sunid, i|
              fm.fork do
                ActiveRecord::Base.establish_connection(config)

                cwd     = pwd
                fam_dir = File.join(configatron.family_dir, "sub", na, sunid.to_s)

                Dir[fam_dir.join("nr*", "*")].each do |subfam_dir|
                  pdbfiles = Dir[subfam_dir.join("*.pdb")]

                  if pdbfiles.size < 2
                    $logger.warn "!!! Only #{pdbfile.size} PDB structure detected in #{subfam_dir}"
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
      fm  = ForkManager.new(configatron.max_fork)

      fm.manage do
        pdb_codes.each_with_index do |pdb_code, i|
          fm.fork do
            [pdb_code + "_aa", pdb_code + "_na"].each do |pdb_stem|
              zap_file = configatron.zip_dir(pdb_stem + '.zap')
              grd_file = configatron.zip_dir(pdb_stem + '.grd')
              err_file = configatron.zip_dir(pdb_stem + '.err')
              pdbfile = configatron.naccess_dir(pdb_stem + '.pdb')

              if File.size? zap_file
                $logger.warn "Skipped, #{pdb_code}: ZAP results files are already there!"
                next
              end

              system "python ./lib/zap_atompot.py -in #{pdbfile} -calc_type remove_self -atomtable 1> #{zap_file} 2> #{err_file}"
            end
            $logger.info ">>> Running ZAP on #{pdb_code}: done (#{i + 1}/#{pdb_codes.size})"
          end
        end
      end
    end


    namespace :joy do

      desc "Run JOY for representative SCOP family alignments"
      task :repaligns => [:environment] do

        $logger.level = Logger::ERROR

        fm = ForkManager.new(configatron.max_fork)
        fm.manage do
          %w[dna rna].each do |na|
            cwd     = pwd
            famdirs = Dir[configatron.family_dir.join("rep", na, "*").to_s]
            famdirs.each do |famdir|
              aligns = Dir[File.join(famdir, "salign*.ali").to_s]

              if aligns.empty?
                $logger.warn "!!! Cannot find alignment files in #{famdir}"
                next
              end

              chdir famdir

              aligns.each do |ali|
                stem    = File.basename(ali, ".ali")
                id      = stem.match(/salign(\d+)/)[1]
                modali  = "mod#{stem}.ali"
                tem     = "mod#{stem}.tem"

                File.open(modali, "w") { |f| f.puts IO.read(ali).gsub(/\.pdb/, "") }

                fm.fork do
                  system "joy #{modali} 1>joy#{id}.stdout 2>joy#{id}.stderr"

                  if !File.exists? tem
                    $logger.error "!!! JOY failed to run with #{modali} in #{famdir}"
                  end
                end
              end

              $logger.info ">>> JOY with alignments in #{famdir}: done"
            end
          end
        end
      end


      desc "Run JOY for SCOP subfamily alignments"
      task :subaligns => [:environment] do

        $logger.level = Logger::ERROR

        fm = ForkManager.new(configatron.max_fork)
        fm.manage do
          %w[dna rna].each do |na|
            cwd         = pwd
            subfamdirs  = Dir[configatron.family_dir.join("sub", na, "*", "*").to_s]
#
#            subfamdirs = %w[
#              /merlin/Live/semin/BiO/Develop/bipa/public/families/sub/rna/50461/1055
#              /merlin/Live/semin/BiO/Develop/bipa/public/families/sub/rna/58120/1305
#              /merlin/Live/semin/BiO/Develop/bipa/public/families/sub/rna/58120/1307
#              /merlin/Live/semin/BiO/Develop/bipa/public/families/sub/rna/58120/1311
#              /merlin/Live/semin/BiO/Develop/bipa/public/families/sub/rna/58120/1320
#              /merlin/Live/semin/BiO/Develop/bipa/public/families/sub/rna/58120/1325
#              /merlin/Live/semin/BiO/Develop/bipa/public/families/sub/rna/58120/1327
#              /merlin/Live/semin/BiO/Develop/bipa/public/families/sub/rna/58120/1333
#              /merlin/Live/semin/BiO/Develop/bipa/public/families/sub/rna/58120/1335
#              /merlin/Live/semin/BiO/Develop/bipa/public/families/sub/rna/58120/1348
#              /merlin/Live/semin/BiO/Develop/bipa/public/families/sub/rna/58120/1351
#              /merlin/Live/semin/BiO/Develop/bipa/public/families/sub/rna/58120/1370
#              /merlin/Live/semin/BiO/Develop/bipa/public/families/sub/rna/58120/1357
#              /merlin/Live/semin/BiO/Develop/bipa/public/families/sub/rna/58120/1379
#              /merlin/Live/semin/BiO/Develop/bipa/public/families/sub/rna/58120/1385
#              /merlin/Live/semin/BiO/Develop/bipa/public/families/sub/rna/58120/1396
#              /merlin/Live/semin/BiO/Develop/bipa/public/families/sub/rna/58120/1404
#              /merlin/Live/semin/BiO/Develop/bipa/public/families/sub/rna/58120/1401
#              /merlin/Live/semin/BiO/Develop/bipa/public/families/sub/rna/58120/1406
#              /merlin/Live/semin/BiO/Develop/bipa/public/families/sub/rna/58120/1405
#              /merlin/Live/semin/BiO/Develop/bipa/public/families/sub/rna/58120/1408
#              /merlin/Live/semin/BiO/Develop/bipa/public/families/sub/rna/58120/1409
#              /merlin/Live/semin/BiO/Develop/bipa/public/families/sub/rna/58120/1412
#              /merlin/Live/semin/BiO/Develop/bipa/public/families/sub/rna/58120/1414
#            ]

            subfamdirs.each do |subfamdir|
              ali = File.join(subfamdir, "salign.ali")

              if !File.exists? ali
                $logger.warn "!!! Cannot find an alignment file in #{subfamdir}"
                next
              end

              chdir subfamdir

              stem    = File.basename(ali, ".ali")
              modali  = "mod#{stem}.ali"
              tem     = "mod#{stem}.tem"

              File.open(modali, "w") { |f| f.puts IO.read(ali).gsub(/\.pdb/, "") }

              fm.fork do
                rm_r Dir['*.sst']
                rm_r Dir['*.psa']
                rm_r Dir['*.hbd']
                rm_r Dir['*.html']
                rm_r Dir['*.ps']
                rm_r Dir['*.rtf']
                rm_r Dir['*.tem']

                Dir['*.pdb'].each do |pdb|
                  stem = File.basename(pdb, '.pdb')
                  system "sstruc s #{pdb} 1>#{stem}.sst.stdout 2>#{stem}.sst.stderr"
                  system "psa #{pdb}      1>#{stem}.psa.stdout 2>#{stem}.psa.stderr"
                  system "hbond #{pdb}    1>#{stem}.hbd.stdout 2>#{stem}.hbd.stderr"
                end

                system "joy #{modali} 1>joy.stdout 2>joy.stderr"

                if !File.exists? tem
                  $logger.error "!!! JOY failed to run with #{modali} in #{subfamdir}"
                end
              end

              chdir cwd
              $logger.info ">>> JOY with an alignment in #{subfamdir}: done"
            end
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
