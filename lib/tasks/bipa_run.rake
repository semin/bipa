namespace :bipa do
  namespace :run do

    require 'fileutils'

    include FileUtils

    def refresh_dir(dir)
      rm_rf(dir) if File.exists?(dir)
      mkdir_p(dir)
    end


    desc "Run Baton on each SCOP family of BIPA"
    task :baton_scop_family => [:environment] do

      refresh_dir(BIPA_ENV[:BATON_SCOP_FAMILY_DIR])
      scop_families = ScopFamily.find(:all).select(&:registered)

      scop_families.each_with_index do |scop_family, i|
        scop_family_dir = File.join(BIPA_ENV[:BATON_SCOP_FAMILY_DIR], "#{scop_family.sccs}")
        mkdir scop_family_dir

        scop_domains = scop_family.all_registered_leaf_children

        scop_domains.each do |scop_domain|
          File.open(File.join(scop_family_dir, "#{scop_domain.sid}.pdb"), "w") do |pdb|
            pdb.puts scop_domain.to_pdb
          end
        end

        puts "Creating PDB flat file for #{scop_family.sccs}: done (#{i + 1}/#{scop_families.size})"
      end
    end


    desc "Run HBPLUS on each PDB file"
    task :hbplus => [:environment] do

      refresh_dir(BIPA_ENV[:HBPLUS_DIR])

      pdb_files = Dir.glob(File.join(BIPA_ENV[:PDB_DIR], '*.pdb'))
      pdb_total = pdb_files.size
      fm        = ForkManager.new(BIPA_ENV[:MAX_FORK])

      fm.manage do
        pdb_files.each_with_index do |pdb_file, i|
          fm.fork do
            pwd = Dir.pwd
            Dir.chdir(BIPA_ENV[:HBPLUS_DIR])
            pdb_file_basename = File.basename(pdb_file, '.pdb')
            File.open(pdb_file_basename + '.clean_stdout', 'w') do |file|
              IO.popen(BIPA_ENV[:CLEAN_BIN], 'r+') do |pipe|
                pipe.puts pdb_file
                file.puts(pipe.readlines)
              end
            end
            Dir.chdir(pwd)
            puts "Running CLEAN on #{pdb_file} (#{i + 1}/#{pdb_total}): done"
          end
        end
      end

      fm = ForkManager.new(BIPA_ENV[:MAX_FORK])
      fm.manage do
        pdb_files.each_with_index do |pdb_file, i|
          fm.fork do
            pwd = Dir.pwd
            Dir.chdir(BIPA_ENV[:HBPLUS_DIR])
            pdb_file_basename = File.basename(pdb_file, '.pdb')
            pdb_new_file      = pdb_file_basename + '.new'
            hbplus_cmd        = ''
            if File.exists? pdb_new_file
              hbplus_cmd = "#{BIPA_ENV[:HBPLUS_BIN]} #{pdb_new_file} #{pdb_file}"
            else
              hbplus_cmd = "#{BIPA_ENV[:HBPLUS_BIN]} #{pdb_file}"
            end
            File.open(pdb_file_basename + '.hbplus_stdout', 'w') do |file|
              IO.popen(hbplus_cmd, 'r') do |pipe|
                file.puts(pipe.readlines)
              end
            end
            Dir.chdir(pwd)
            puts "Running HBPLUS on #{pdb_file} (#{i + 1}/#{pdb_total}): done"
          end # fm.fork
        end # pdb_files.each_with_index
      end # fm.manage
    end # task :hbplus


    desc "Run NACCESS on each PDB file"
    task :naccess => [:environment] do

      refresh_dir(BIPA_ENV[:NACCESS_DIR])

      pdb_files = Dir.glob(File.join(BIPA_ENV[:PDB_DIR], '*.pdb'))
      pdb_total = pdb_files.size

      # Run naccess for every protein-nulceic acid complex,
      # 1) protein only,
      # 2) nucleic acid only,
      # 3) and protein-nucleic acid complex

      fm = ForkManager.new(BIPA_ENV[:MAX_FORK])
      fm.manage do
        pwd = Dir.pwd
        pdb_files.each_with_index do |pdb_file, i|
          fm.fork do
            pdb_code  = File.basename(pdb_file, '.pdb')
            pdb_str   = IO.readlines(pdb_file).join
            pdb_obj   = Bio::PDB.new(pdb_str)
            tmp_dir   = File.join(BIPA_ENV[:NACCESS_DIR], pdb_code)

            mkdir(tmp_dir)
            cp(pdb_file, tmp_dir)
            Dir.chdir(tmp_dir)

            aa_pdb_file = "#{pdb_code}_aa.pdb"
            File.open(aa_pdb_file, 'w') do |f|
              f.puts pdb_obj.models[0].aa_chains.to_s
            end

            na_pdb_file = "#{pdb_code}_na.pdb"
            File.open(na_pdb_file, 'w') do |f|
              f.puts pdb_obj.models[0].na_chains.to_s
            end

            system("#{BIPA_ENV[:NACCESS_BIN]} #{pdb_code}.pdb -r #{BIPA_ENV[:NACCESS_VDW]} -s #{BIPA_ENV[:NACCESS_STD]}")
            system("#{BIPA_ENV[:NACCESS_BIN]} #{aa_pdb_file}  -r #{BIPA_ENV[:NACCESS_VDW]} -s #{BIPA_ENV[:NACCESS_STD]}")
            system("#{BIPA_ENV[:NACCESS_BIN]} #{na_pdb_file}  -r #{BIPA_ENV[:NACCESS_VDW]} -s #{BIPA_ENV[:NACCESS_STD]}")

            cp(Dir.glob("#{pdb_code}*"), '..')
            Dir.chdir(pwd)
            rm_r(tmp_dir)

            puts "Running NACCESS on #{pdb_file} (#{i + 1}/#{pdb_total}): done"
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
