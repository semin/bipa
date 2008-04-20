namespace :bipa do
  namespace :run do

    include FileUtils

    desc "Run HBPLUS on each PDB file"
    task :hbplus => [:environment] do

      refresh_dir(HBPLUS_DIR)

      pdb_files = Dir[File.join(PDB_DIR, "*.pdb")]
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do

        pdb_files.each_with_index do |pdb_file, i|

          fmanager.fork do
            cwd       = pwd
            pdb_code  = File.basename(pdb_file, ".pdb")
            work_dir  = File.join(HBPLUS_DIR, pdb_code)

            mkdir_p(work_dir)
            chdir(work_dir)

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

            system("#{HBPLUS_BIN} #{pdb_file} 1>#{pdb_code}.hbplus.log 2>&1")
            move(Dir["*"], "..")
            chdir(cwd)
            rm_rf(work_dir)

            $logger.info("HBPLUS: #{pdb_file} (#{i + 1}/#{pdb_files.size}): done")
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

      refresh_dir(NACCESS_DIR)

      pdb_files = Dir[File.join(PDB_DIR, "*.pdb")].sort
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do

        pdb_files.each_with_index do |pdb_file, i|

          fmanager.fork do
            cwd       = pwd
            pdb_code  = File.basename(pdb_file, ".pdb")
            pdb_obj   = Bio::PDB.new(IO.read(pdb_file))
            work_dir  = File.join(NACCESS_DIR, pdb_code)

            if (pdb_obj.models.first.aa_chains.empty? ||
                pdb_obj.models.first.na_chains.empty?)
              $logger.warn("SKIP: #{pdb_file} has no amino acid chain or nucleic acid chain")
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

            system("#{NACCESS_BIN} #{co_pdb_file} -h -r #{NACCESS_VDW} -s #{NACCESS_STD}")
            system("#{NACCESS_BIN} #{aa_pdb_file} -h -r #{NACCESS_VDW} -s #{NACCESS_STD}")
            system("#{NACCESS_BIN} #{na_pdb_file} -h -r #{NACCESS_VDW} -s #{NACCESS_STD}")

            cp(Dir["#{pdb_code}*"], "..")
            chdir(cwd)
            rm_r(work_dir)

            $logger.info("NACCESS: #{pdb_file} (#{i + 1}/#{pdb_files.size}): done")
          end
        end
      end
    end


    desc "Run DSSP on each PDB file"
    task :dssp => [:environment] do

      refresh_dir(DSSP_DIR)

      pdb_files = Dir[File.join(PDB_DIR, "*.pdb")]
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do

        pdb_files.each_with_index do |pdb_file, i|

          fmanager.fork do
            cwd = pwd
            chdir(DSSP_DIR)
            pdb_code = File.basename(pdb_file, '.pdb')
            system("#{DSSP_BIN} #{pdb_file} 1> #{pdb_code}.dssp 2> #{pdb_code}.dssp.err")
            chdir(cwd)

            $logger.info("Running DSSP on #{pdb_file} (#{i + 1}/#{pdb_files.size}): done")
          end
        end
      end
    end


    desc "Run blastclust for each SCOP family"
    task :blastclust => [:environment] do

      refresh_dir(BLASTCLUST_DIR)

      sunids    = ScopFamily.registered.find(:all, :select => "sunid").map(&:sunid)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        sunids.each_with_index do |sunid, i|

          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)

            family    = ScopFamily.find_by_sunid(sunid)
            fam_dir   = File.join(BLASTCLUST_DIR, "#{family.sunid}")
            fam_fasta = File.join(fam_dir, "#{family.sunid}.fa")

            mkdir(fam_dir)

            File.open(fam_fasta, "w") do |file|
              domains = family.all_registered_leaf_children

              domains.each do |domain|
                if domain.to_sequence.include?("X")
                  puts "Skip: SCOP domain, #{domain.sunid} has some unknown residues!"
                  next
                end

                file.puts ">#{domain.sunid}"
                file.puts domain.to_sequence
              end
            end

            (10..100).step(10) do |si|
              blastclust_cmd =
                "blastclust " +
                "-i #{fam_fasta} "+
                "-o #{File.join(fam_dir, family.sunid.to_s + '.cluster' + si.to_s)} " +
                "-L .9 " +
                "-S #{si} " +
                "-a 2 " +
                "-p T"
                system blastclust_cmd
            end

            ActiveRecord::Base.remove_connection
            $logger.info("Creating cluster files for SCOP family, #{sunid}: done (#{i+1}/#{sunids.size})")
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


    namespace :baton do

      desc "Run Baton for each SCOP family"
      task :full_scop_pdb_files => [:environment] do

        sunids    = ScopFamily.registered.find(:all).map(&:sunid).sort
        full_dir  = File.join(FAMILY_DIR, "full")
        fmanager  = ForkManager.new(MAX_FORK)

        fmanager.manage do

          sunids.each_with_index do |sunid, i|

            fmanager.fork do
              cwd       = pwd
              fam_dir   = File.join(full_dir, sunid.to_s)
              pdb_list  = Dir[fam_dir + "/*.pdb"].map { |p| p.match(/(\d+)\.pdb$/)[1] }

              next unless pdb_list.size > 0

              clst_file = File.join(BLASTCLUST_DIR, sunid.to_s, "#{sunid}.nr90.fa")
              clst_list = IO.readlines(clst_file).map { |l| l.chomp.split(/\s+/) }.compact.flatten
              list      = (clst_list & pdb_list).map { |p| p + ".pdb" }

              chdir(fam_dir)
              ENV["PDB_EXT"] = ".pdb"
              File.open("LIST", "w") { |f| f.puts list.join("\n") }
              system("Baton -input /BiO/Install/Baton/data/baton.prm.current -features -pdbout -matrixout -list LIST 1>baton.log 2>&1")
              chdir(cwd)

              $logger.info("Baton with full set of SCOP Family, #{sunid}: done (#{i + 1}/#{sunids.size})")
            end
          end
        end
      end


      desc "Run Baton for representative PDB files for each SCOP Family"
      task :rep_scop_pdb_files => [:environment] do

        sunids    = ScopFamily.registered.find(:all).map(&:sunid).sort
        fmanager  = ForkManager.new(MAX_FORK)

        fmanager.manage do

          sunids.each_with_index do |sunid, i|

            fmanager.fork do

              (10..100).step(10) do |si|
                cwd     = pwd
                rep_dir = File.join(FAMILY_DIR, "rep#{si}", "#{sunid}")
                chdir(rep_dir)
                system("Baton -input /home/merlin/Temp/baton.prm.current -features -pdbout -matrixout *.pdb 1> baton.log 2>&1")
                chdir(cwd)
              end

              $logger.info("BATON with representative PDB files for SCOP Family: #{sunid}: done (#{i + 1}/#{sunids.size})")
            end
          end
        end
      end


      desc "Run Baton for each subfamilies of SCOP families"
      task :sub_scop_pdb_files => [:environment] do

        sunids    = ScopFamily.registered.find(:all).map(&:sunid).sort
        sub_dir   = File.join(FAMILY_DIR, "sub")
        fmanager  = ForkManager.new(MAX_FORK)

        fmanager.manage do

          sunids.each_with_index do |sunid, i|

            fmanager.fork do
              cwd     = pwd
              fam_dir = File.join(sub_dir, sunid.to_s)

              (10..100).step(10) do |si|
                rep_dir = File.join(fam_dir, "rep#{si}")

                Dir[rep_dir + "/*"].each do |subfam_dir|
                  chdir(subfam_dir)
                  system("Baton -input /home/merlin/Temp/baton.prm.current -features -pdbout -matrixout *.pdb 1> baton.log 2>&1")
                  chdir(cwd)
                end
              end

              $logger.info("BATON with subfamily PDB files for SCOP Family: #{sunid}: done (#{i + 1}/#{sunids.size})")
            end
          end
        end
      end

    end # namespace :baton


    desc "Run JOY for each SCOP family"
    task :joy => [:environment] do

      sunids    = ScopFamily.registered.find(:all).map(&:sunid)
      full_dir  = File.join(FAMILY_DIR, "full")
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do

        sunids.each_with_index do |sunid, i|

          fmanager.fork do
            cwd     = pwd
            fam_dir = File.join(full_dir, sunid.to_s)
            chdir(fam_dir)

            Dir["*.pdb"].each do |pdb_file|
              system("joy #{pdb_file} 1> #{pdb_file.gsub(/\.pdb/, '') + '.joy.log'} 2>&1")
            end
            chdir(cwd)

            $logger.info("JOY with full set of SCOP Family: #{sunid}: done (#{i + 1}/#{sunids.size})")

#            (10..100).step(10) do |si|
#
#              cwd = pwd
#              fam_dir = File.join(FAMILY_DIR, "nr#{si}", "#{sunid}")
#              chdir(fam_dir)
#              system("joy baton.ali 1> joy.log 2>&1")
#              chdir(cwd)
#
#              $logger.info("JOY with NR: #{si}, SCOP Family: #{sunid}: done (#{i + 1}/#{sunids.size})")
#            end

          end # fmanager.fork
        end
      end
    end


    desc "Run ZAP for each SCOP Domain PDB file"
    task :zap => [:environment] do

      refresh_dir(ZAP_DIR)

      pdb_codes = Dir[NACCESS_DIR + "/*_aa.asa"].map { |f| f.match(/(\S{4})_aa/)[1] }.sort
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do

        pdb_codes.each_with_index do |pdb_code, i|

          fmanager.fork do

            [pdb_code + "_aa", pdb_code + "_na"].each do |pdb_stem|
              zap_file = File.join(ZAP_DIR, pdb_stem + '.zap')
              grd_file = File.join(ZAP_DIR, pdb_stem + '.grd')
              err_file = File.join(ZAP_DIR, pdb_stem + '.err')
              pdb_file = File.join(NACCESS_DIR, pdb_stem + '.pdb')
              next if File.exists? zap_file

              #system "python ./lib/zap_atompot.py -in #{pdb_file} -grid_file #{grd_file} -calc_type remove_self -atomtable 1> #{zap_file} 2> #{err_file}"
              system "python ./lib/zap_atompot.py -in #{pdb_file} -calc_type remove_self -atomtable 1> #{zap_file} 2> #{err_file}"
            end
            $logger.info("ZAP: #{pdb_code} (#{i + 1}/#{pdb_codes.size}): done")
          end
        end
      end
    end

  end
end
