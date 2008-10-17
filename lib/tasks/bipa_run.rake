namespace :bipa do
  namespace :run do

    include FileUtils

    desc "Run HBPLUS on each PDB file"
    task :hbplus => [:environment] do

      refresh_dir HBPLUS_DIR

      pdb_files = FileList[File.join(PDB_DIR, "*.pdb")]
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do

        pdb_files.each_with_index do |pdb_file, i|

          fmanager.fork do
            cwd       = pwd
            pdb_code  = File.basename(pdb_file, ".pdb")
            work_dir  = File.join(HBPLUS_DIR, pdb_code)

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

      refresh_dir NACCESS_DIR

      pdb_files = FileList[File.join(PDB_DIR, "*.pdb")].sort
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

      refresh_dir DSSP_DIR

      pdb_files = FileList[File.join(PDB_DIR, "*.pdb")]
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        pdb_files.each_with_index do |pdb_file, i|
          fmanager.fork do
            cwd = pwd
            chdir DSSP_DIR
            pdb_code = File.basename(pdb_file, '.pdb')
            sh "#{DSSP_BIN} #{pdb_file} 1> #{pdb_code}.dssp 2> #{pdb_code}.dssp.err"
            chdir cwd

            $logger.info ">>> Running DSSP on #{pdb_file} (#{i + 1}/#{pdb_files.size}): done"
          end
        end
      end
    end


    desc "Run blastclust for each SCOP family"
    task :blastclust => [:environment] do

      refresh_dir(BLASTCLUST_DIR) unless RESUME

      sunids    = ScopFamily.registered.find(:all, :select => "sunid").map(&:sunid)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        sunids.each_with_index do |sunid, i|

          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)

            family    = ScopFamily.find_by_sunid(sunid)
            fam_dir   = File.join(BLASTCLUST_DIR, "#{sunid}")
            fam_fasta = File.join(fam_dir, "#{sunid}.fa")

            mkdir(fam_dir)

            domains = family.all_registered_leaf_children

            domains.each do |domain|
              if domain.to_sequence.include?("X")
                puts "Skip: SCOP domain, #{domain.sunid} has some unknown residues!"
                next
              end
              File.open(fam_fasta, "a") do |file|
                file.puts ">#{domain.sunid}"
                file.puts domain.to_sequence
              end
            end

            if File.size?(fam_fasta)
              (10..100).step(10) do |si|
                blastclust_cmd =
                  "blastclust " +
                  "-i #{fam_fasta} "+
                  "-o #{File.join(fam_dir, family.sunid.to_s + '.cluster' + si.to_s)} " +
                  "-L .9 " +
                  "-S #{si} " +
                  "-a 2 " +
                  "-p T"
                  sh blastclust_cmd
              end
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

              clst_file = File.join(BLASTCLUST_DIR, sunid.to_s, "#{sunid}.cluster90")
              clst_list = IO.readlines(clst_file).map { |l| l.chomp.split(/\s+/) }.compact.flatten
              list      = (clst_list & pdb_list).map { |p| p + ".pdb" }

              chdir(fam_dir)
              ENV["PDB_EXT"] = ".pdb"
              File.open("LIST", "w") { |f| f.puts list.join("\n") }
              sh "Baton -input /BiO/Install/Baton/data/baton.prm.current -features -pdbout -matrixout -list LIST 1>baton.log 2>&1"
              chdir(cwd)

              $logger.info("Baton with full set of SCOP Family, #{sunid}: done (#{i + 1}/#{sunids.size})")
            end
          end
        end
      end


      desc "Run Baton for representative PDB files for each SCOP Family"
      task :rep_scop_pdb_files => [:environment] do

        sunids    = ScopFamily.registered.find(:all, :select => "sunid").map(&:sunid).sort
        fmanager  = ForkManager.new(MAX_FORK)

        fmanager.manage do

          sunids.each_with_index do |sunid, i|

            fmanager.fork do

              (10..100).step(10) do |si|
                cwd       = pwd
                pre_si    = si > 10 ? si - 10 : si
                rep_dir   = File.join(FAMILY_DIR, "rep#{si}", "#{sunid}")
                pdb_list  = Dir[rep_dir + "/*.pdb"].map { |p| p.match(/(\d+)\.pdb$/)[1] }

                next unless pdb_list.size > 0

                clst_file = File.join(BLASTCLUST_DIR, sunid.to_s, "#{sunid}.cluster#{pre_si}")
                clst_list = IO.readlines(clst_file).map { |l| l.chomp.split(/\s+/) }.compact.flatten
                list      = (clst_list & pdb_list).map { |p| p + ".pdb" }

                chdir(rep_dir)
                ENV["PDB_EXT"] = ".pdb"
                File.open("LIST", "w") { |f| f.puts list.join("\n") }
                sh "Baton -input /BiO/Install/Baton/data/baton.prm.current -features -pdbout -matrixout -list LIST 1>baton.log 2>&1"
                chdir(cwd)
              end

              $logger.info("BATON with representative PDB files for SCOP Family, #{sunid}: done (#{i + 1}/#{sunids.size})")
            end
          end
        end
      end


      desc "Run Baton for each subfamilies of SCOP families"
      task :sub_scop_pdb_files => [:environment] do

        sunids    = ScopFamily.registered.find(:all, :select => "sunid").map(&:sunid).sort
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
                  sh "Baton -input /BiO/Install/Baton/data/baton.prm.current -features -pdbout -matrixout *.pdb 1>baton.log 2>&1"
                  chdir(cwd)
                end
              end

              $logger.info("BATON with subfamily PDB files for SCOP Family, #{sunid}: done (#{i + 1}/#{sunids.size})")
            end
          end
        end
      end

    end # namespace :baton


    desc "Run JOY for each SCOP family alignment"
    task :joy => [:environment] do

      fmanager  = ForkManager.new(MAX_FORK)
      fmanager.manage do
        (10..100).step(10) do |si|
          rep_dir = File.join(ALIGNMENT_DIR, "rep#{si}")

          fmanager.fork do
            Dir.new(rep_dir).each do |dir|
              if dir =~ /^\./ then next end # skip if . or ..
              cwd = pwd
              fam_dir = File.join(rep_dir, dir)
              chdir(fam_dir)
              sh "joy baton.ali 1> joy.log 2>&1"
              chdir(cwd)

              $logger.info "JOY with non-redundant set (#{si} pid) of SCOP Family, #{dir}: done"
            end
          end # fmanager.fork

        end
      end
    end


    desc "Run ZAP for each SCOP Domain PDB file"
    task :zap => [:environment] do

      refresh_dir(ZAP_DIR) unless RESUME

      pdb_codes = FileList[NACCESS_DIR + "/*_aa.asa"].map { |f| f.match(/(\S{4})_aa/)[1] }.sort
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        pdb_codes.each_with_index do |pdb_code, i|
          fmanager.fork do
            [pdb_code + "_aa", pdb_code + "_na"].each do |pdb_stem|
              zap_file = File.join(ZAP_DIR, pdb_stem + '.zap')
              grd_file = File.join(ZAP_DIR, pdb_stem + '.grd')
              err_file = File.join(ZAP_DIR, pdb_stem + '.err')
              pdb_file = File.join(NACCESS_DIR, pdb_stem + '.pdb')

              if File.size? zap_file
                $logger.info("Skip #{pdb_code}, ZAP results files are already there!")
                next
              end

              #sh "python ./lib/zap_atompot.py -in #{pdb_file} -grid_file #{grd_file} -calc_type remove_self -atomtable 1> #{zap_file} 2> #{err_file}"
              system "python ./lib/zap_atompot.py -in #{pdb_file} -calc_type remove_self -atomtable 1> #{zap_file} 2> #{err_file}"
            end
            $logger.info ">>> Running ZAP on #{pdb_code}: done (#{i + 1}/#{pdb_codes.size})"
          end
        end
      end
    end


    desc "Run fugueprf for each profiles of all non-redundant sets of SCOP families"
    task :fugueprf => [:environment] do

      (10..100).step(10) do |si|
        next if si != 90

        %w[dna rna].each do |na|
          %w[16 32 std].each do |env|
            est_dir = File.join(ESST_DIR, "rep#{si}", "#{na}#{env}")
            seq     = ASTRAL40
            cwd     = pwd
            chdir dir

            FileList[est_dir + "/*.fug"].each_with_index do |fug, i|
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

      (10..100).step(10) do |si|
        next if si != 90

        %w[dna rna].each do |na|
          %w[16 32 std].each do |env|
            cwd     = pwd
            est_dir = File.join(ESST_DIR, "rep#{si}", "#{na}#{env}")
            master  = nil

            chdir est_dir

            FileList["./*.tem"].each do |tem_file|
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
                  system "#{BALISCORE_BIN} #{temp}-#{sunid}.ref.msf #{temp}-#{sunid}.na.fug.msf > #{temp}-#{sunid}.na.fug.bb"

                  system "fugueali -seq #{sunid}.ali -prf #{temp}.std.fug -y -o #{temp}-#{sunid}.std.fug.ali"
                  system "mview -in pir -out msf #{temp}-#{sunid}.std.fug.ali > #{temp}-#{sunid}.std.fug.msf"
                  system "#{BALISCORE_BIN} #{temp}-#{sunid}.ref.msf #{temp}-#{sunid}.std.fug.msf > #{temp}-#{sunid}.std.fug.bb"

                  system "needle -asequence #{temp}.ali -bsequence #{sunid}.ali -aformat msf -outfile #{temp}-#{sunid}.ndl.msf -gapopen 10.0 -gapextend 0.5"
                  system "#{BALISCORE_BIN} #{temp}-#{sunid}.ref.msf #{temp}-#{sunid}.ndl.msf > #{temp}-#{sunid}.ndl.bb"

                  system "cat #{temp}.ali #{sunid}.ali > #{temp}-#{sunid}.ali"
                  system "clustalw2 -INFILE=#{temp}-#{sunid}.ali -ALIGN -OUTFILE=#{temp}-#{sunid}.clt.msf -OUTPUT=GCG"
                  system "#{BALISCORE_BIN} #{temp}-#{sunid}.ref.msf #{temp}-#{sunid}.clt.msf > #{temp}-#{sunid}.clt.bb"
                end
              end
            end
          end
          chdir cwd
        end
      end
    end

  end
end
