namespace :bipa do
  namespace :run do

    include FileUtils

    desc "Run HBPLUS on each PDB file"
    task :hbplus => [:environment] do

      refresh_dir(HBPLUS_DIR) if !ENV["RESUME"]

      pdb_files = Dir[File.join(PDB_DIR, "*.pdb")]
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do

        pdb_files.each_with_index do |pdb_file, i|

          fmanager.fork do

            cwd = pwd

            pdb_code = File.basename(pdb_file, ".pdb")
            work_dir = File.join(HBPLUS_DIR, pdb_code)

            if ENV["RESUME"] && File.exists?(File.join(HBPLUS_DIR, "#{pdb_code}.hb2"))
              $logger.info("HBPLUS: #{pdb_file} (#{i + 1}/#{pdb_files.size}): skip")
              next
            end

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
            $logger.info("HBPLUS: #{pdb_file} (#{i + 1}/#{pdb_files.size}): done")

            move(Dir["*"], "..")
            chdir(cwd)
            rm_rf(work_dir)
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

      cwd       = pwd
      pdb_files = Dir[File.join(PDB_DIR, "*.pdb")]
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do

        pdb_files.each_with_index do |pdb_file, i|

          fmanager.fork do

            pdb_code  = File.basename(pdb_file, ".pdb")
            pdb_str   = IO.readlines(pdb_file).join
            pdb_obj   = Bio::PDB.new(pdb_str)
            work_dir  = File.join(NACCESS_DIR, pdb_code)

            mkdir(work_dir)
            cp(pdb_file, work_dir)
            chdir(work_dir)

            aa_pdb_file = "#{pdb_code}_aa.pdb"
            File.open(aa_pdb_file, "w") do |f|
              f.puts pdb_obj.models.first.aa_chains.to_s
            end

            na_pdb_file = "#{pdb_code}_na.pdb"
            File.open(na_pdb_file, "w") do |f|
              f.puts pdb_obj.models.first.na_chains.to_s
            end

            system("#{NACCESS_BIN} #{pdb_code}.pdb -r #{NACCESS_VDW} -s #{NACCESS_STD}")
            system("#{NACCESS_BIN} #{aa_pdb_file}  -r #{NACCESS_VDW} -s #{NACCESS_STD}")
            system("#{NACCESS_BIN} #{na_pdb_file}  -r #{NACCESS_VDW} -s #{NACCESS_STD}")

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

      fmanager = ForkManager.new(MAX_FORK)
      fmanager.manage do
        pdb_files.each_with_index do |pdb_file, i|
          fmanager.fork do
            cwd = pwd
            chdir(DSSP_DIR)
            pdb_code = File.basename(pdb_file, '.pdb')
            system("#{DSSP_BIN} #{pdb_file} 1> #{pdb_code}.dssp 2> #{pdb_code}.dssp.err")
            $logger.info("Running DSSP on #{pdb_file} (#{i + 1}/#{pdb_files.size}): done")
            chdir(cwd)
          end
        end
      end
    end


    desc "Run blastclust for each SCOP family"
    task :blastclust => [:environment] do

      refresh_dir(BLASTCLUST_DIR)

      families = ScopFamily.registered
      families.each_with_index do |family, i|

        family_dir    = File.join(BLASTCLUST_DIR, "#{family.sunid}")
        family_fasta  = File.join(family_dir, "#{family.sunid}.fa")

        mkdir(family_dir)

        File.open(family_fasta, "w") do |file|

          domains = family.all_registered_leaf_children
          domains.each do |domain|

            sunid = domain.sunid
            fasta = domain.to_fasta

            if fasta.include?("X")
              puts "Skip: SCOP domain, #{sunid} has some unknown residues!"
              next
            end

            file.puts ">#{sunid}"
            file.puts fasta
          end
        end

        (10..100).step(10) do |si|
          blastclust_cmd =
            "blastclust " +
            "-i #{family_fasta} "+
            "-o #{File.join(family_dir, family.sunid.to_s + '.nr' + si.to_s + '.fa')} " +
            "-L .9 " +
            "-S #{si} " +
            "-a 2 " +
            "-p T"
            system blastclust_cmd
        end

        $logger.info("Creating non-redundant fasta files for SCOP family, #{family.sunid} : done (#{i+1}/#{families.size})")
      end
    end


    desc "Run Baton and JOY for each SCOP family"
    task :baton_and_joy => [:environment] do

      nr_cutoff     = 100
      nr_dir        = File.join(BATON_DIR, "nr#{nr_cutoff}")
      family_sunids = ScopFamily.registered.map(&:sunid)
      fmanager      = ForkManager.new(MAX_FORK)

      refresh_dir(nr_dir)

      fmanager.manage do

        config = ActiveRecord::Base.remove_connection

        family_sunids.each_with_index do |family_sunid, i|

          fmanager.fork do

            ActiveRecord::Base.establish_connection(config)

            family      = ScopFamily.find_by_sunid(family_sunid)
            family_dir  = File.join(nr_dir, "#{family_sunid}")

            mkdir(family_dir)

            subfamilies = family.send("subfamilies#{nr_cutoff}")
            subfamilies.each do |subfamily|
              domain = subfamily.representative
              next if domain.nil?
              File.open(File.join(family_dir, "#{domain.sunid}.pdb"), "w") do |file|
                file.puts domain.to_pdb
              end
            end

            ActiveRecord::Base.remove_connection
          end

          ActiveRecord::Base.establish_connection(config)
          $logger.info("NR(#{nr_cutoff}): Creating PDB files for #{family_sunid}: done (#{i + 1}/#{family_sunids.size})")
        end
      end

      # Baton & JOY
      fmanager = ForkManager.new(MAX_FORK)

      fmanager.manage do

        family_sunids.each_with_index do |family_sunid, i|

          fmanager.fork do

            cwd = pwd
            family_dir = File.join(nr_dir, "#{family_sunid}")
            chdir(family_dir)
            system("Baton *.pdb")
            system("joy baton.ali")
            chdir(cwd)

            $logger.info("NR(#{nr_cutoff}): Running Baton and JOY on PDB files for #{family_sunid}: done (#{i + 1}/#{family_sunids.size})")
          end
        end
      end
    end

  end
end
