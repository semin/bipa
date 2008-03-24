namespace :bipa do
  namespace :run do

    include FileUtils

    desc "Run blastclust for each SCOP family"
    task :blastclust_scop_families => [:environment] do

      refresh_dir(BLASTCLUST_DIR)

      families = ScopFamily.find_registered(:all)
      families.each_with_index do |family, i|

        family_dir    = File.join(BIPA_ENV[:BLASTCLUST_SCOP_FAMILY_DIR], "#{family.sunid}")
        family_fasta  = File.join(family_dir, "#{family.sunid}.fa")
        mkdir family_dir

        File.open(family_fasta, "w") do |file|

          domains = family.all_registered_leaf_children
          domains.each do |domain|
            sunid = domain.sunid
            fasta = domain.to_fasta

            if fasta.include? "X"
              puts "Skip: SCOP domain, #{sunid} has some unknown residues!"
              next
            end

            file.puts ">#{sunid}"
            file.puts fasta
          end
        end

        (10..100).step(10) do |id|
          blastclust_cmd =
            "blastclust " +
            "-i #{family_fasta} "+
            "-o #{File.join(family_dir, family.sunid.to_s + '.nr' + id.to_s + '.fa')} " +
            "-L .9 " +
            "-S #{id} " +
            "-a 2 " +
            "-p T"
            system blastclust_cmd
        end

        puts "Creating non-redundant fasta files for SCOP family, #{family.sunid} : done (#{i+1}/#{families.size})"
      end
    end


    desc "Run Baton and JOY for each SCOP family"
    task :baton_and_joy_scop_families => [:environment] do

      nr_cutoff     = BIPA_ENV[:NR_CUTOFF]
      nr_dir        = File.join(BIPA_ENV[:BATON_SCOP_FAMILY_DIR], "nr#{nr_cutoff}")
      family_sunids = ScopFamily.find_registered(:all).map(&:sunid)
      fmanager      = ForkManager.new(BIPA_ENV[:MAX_FORK])
      refresh_dir nr_dir

      # NR SCOP domain PDB files for each SCOP family
      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        family_sunids.each_with_index do |family_sunid, i|
          fmanager.fork do

            ActiveRecord::Base.establish_connection(config)

            family = ScopFamily.find_by_sunid(family_sunid)
            family_dir = File.join(nr_dir, "#{family_sunid}")
            mkdir family_dir

            clusters = family.send("cluster#{nr_cutoff}s")
            clusters.each do |cluster|
              domain = cluster.representative
              next if domain.nil?
              File.open(File.join(family_dir, "#{domain.sunid}.pdb"), "w") do |pdb|
                pdb.puts domain.to_pdb
              end
            end
            ActiveRecord::Base.remove_connection
          end

          puts "NR(#{nr_cutoff}): Creating PDB files for #{family_sunid}: done (#{i + 1}/#{family_sunids.size})"
          ActiveRecord::Base.establish_connection(config)
        end
      end

      # Baton & JOY
      fmanager = ForkManager.new(BIPA_ENV[:MAX_FORK])
      fmanager.manage do
        family_sunids.each_with_index do |family_sunid, i|

          fmanager.fork do
            cwd = pwd
            family_dir = File.join(nr_dir, "#{family_sunid}")
            chdir family_dir
            system "Baton *.pdb"
            system "joy baton.ali"
            chdir cwd

            puts "NR(#{nr_cutoff}): Running Baton and JOY on PDB files for #{family_sunid}: done (#{i + 1}/#{family_sunids.size})"
          end
        end
      end
    end


    desc "Run HBPLUS on each PDB file"
    task :hbplus => [:environment] do

      refresh_dir(HBPLUS_DIR)

      pdb_files = Dir[File.join(PDB_DIR, "*.pdb")]
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        pdb_files.each_with_index do |pdb_file, i|
          fmanager.fork do

            cwd = pwd

            pdb_code = File.basename(pdb_file, ".pdb")
            work_dir = File.join(HBPLUS_DIR, pdb_code)

            mkdir_p(work_dir)
            chdir(work_dir)

            # CLEAN
            File.open(pdb_code + ".clean_stdout", "w") do |log|
              IO.popen(CLEAN_BIN, "r+") do |pipe|
                pipe.puts pdb_file
                log.puts pipe.readlines
              end
            end
            $logger.info("CLEAN: #{pdb_file} (#{i + 1}/#{pdb_files.size}): done")

            # NACCESS
            new_pdb_file  = pdb_code + ".new"
            naccess_input = File.exists?(new_pdb_file) ? new_pdb_file : pdb_file
            naccess_cmd   = "#{NACCESS_BIN} #{naccess_input} -p 1.40 -r #{NACCESS_VDW} -s #{NACCESS_STD} -z 0.05"

            File.open(pdb_code + ".naccess.log", "w") do |log|
              IO.popen(naccess_cmd, "r") do |pipe|
                log.puts pipe.readlines
              end
            end
            $logger.info("NACCESS: #{naccess_input} (#{i + 1}/#{pdb_files.size}): done")

            # HBADD
            hbadd_cmd = "#{HBADD_BIN} #{naccess_input} #{HET_DICT_FILE}"

            File.open(pdb_code + ".hbadd.log", "w") do |log|
              IO.popen(hbadd_cmd, "r") do |pipe|
                log.puts pipe.readlines
              end
            end
            $logger.info("HBADD: #{naccess_input} (#{i + 1}/#{pdb_files.size}): done")

            # HBPLUS
            if File.exists?(new_pdb_file)
              hbplus_cmd = "#{HBPLUS_BIN} -x -R -q #{new_pdb_file} #{pdb_file}"
            else
              hbplus_cmd = "#{HBPLUS_BIN} -x -R -q #{pdb_file}"
            end

            if File.exists?("hbplus.rc")
              mv "hbplus.rc", "#{pdb_code}.rc"
              hbplus_cmd += " -f #{pdb_code}.rc"
            end

            File.open(pdb_code + ".hbplus.log", "w") do |log|
              IO.popen(hbplus_cmd, "r") do |pipe|
                log.puts pipe.readlines
              end
            end
            $logger.info("HBPLUS: #{pdb_file} (#{i + 1}/#{pdb_files.size}): done")

            move(Dir["*"], HBPLUS_DIR)
            rm_rf(work_dir)
            chdir(cwd)
          end
        end
      end
    end # task :hbplus


    desc "Run NACCESS on each PDB file"
    task :naccess => [:environment] do

      refresh_dir(NACCESS_DIR)

      pdb_files = Dir[File.join(PDB_DIR, "*.pdb")]

      # Run naccess for every protein-nulceic acid complex,
      # 1) protein only,
      # 2) nucleic acid only,
      # 3) and protein-nucleic acid complex

      fmanager = ForkManager.new(MAX_FORK)
      fmanager.manage do
        cwd = pwd
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
            chdir(pwd)
            rm_r(work_dir)

            $logger.info("NACCESS: #{pdb_file} (#{i + 1}/#{pdb_files.size}): done")
          end
        end
      end
    end


    desc "Run DSSP on each PDB file"
    task :dssp => [:environment] do
      refresh_dir(BIPA_ENV[:DSSP_DIR])
      pdb_files = Dir.glob(File.join(BIPA_ENV[:PDB_DIR], '*.pdb'))
      pdb_total = pdb_files.size

      fm = ForkManager.new(BIPA_ENV[:MAX_FORK])
      fm.manage do
        pdb_files.each_with_index do |pdb_file, i|
          fm.fork do
            pwd = Dir.pwd
            Dir.chdir(BIPA_ENV[:DSSP_DIR])
            pdb_code = File.basename(pdb_file, '.pdb')
            system("#{BIPA_ENV[:DSSP_BIN]} #{pdb_file} 1> #{pdb_code}.dssp 2> #{pdb_code}.dssp.stderr")
            puts ("Running DSSP on #{pdb_file} (#{i + 1}/#{pdb_total}): done")
            Dir.chdir(pwd)
          end
        end
      end
    end

  end
end
