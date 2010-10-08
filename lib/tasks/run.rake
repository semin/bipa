namespace :run do
  namespace :bipa do

    desc "Run HBPLUS on each PDB file"
    task :hbplus => [:environment] do

      refresh_dir configatron.hbplus_dir

      fm    = ForkManager.new(configatron.max_fork)
      pdbs  = Dir[configatron.pdb_dir + "*.pdb"].to_pathnames

      fm.manage do
        pdbs.each_with_index do |pdb, i|
          fm.fork do
            cwd       = pwd
            pdb_code  = pdb.basename(".pdb")
            work_dir  = configatron.hbplus_dir + pdb_code

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
#            naccess_cmd   = "#{configatron.naccess_bin} #{naccess_input} -p 1.40 -z 0.05 -r #{configatron.naccess_vdw} -s #{configatron.naccess_std}"
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

            cmd = "#{configatron.hbplus_bin} -c #{pdb} 1>#{pdb_code}.hbplus.log 2>&1"
            system cmd
            move Dir["*"], ".."
            chdir cwd
            rm_rf work_dir

            $logger.info "Running 'hbplus' with #{pdb} (#{i + 1}/#{pdbs.size}): done"
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
      pdbs  = Dir[configatron.pdb_dir + "*.pdb"].to_pathnames

      fm.manage do
        pdbs.each_with_index do |pdb, i|
          fm.fork do
            cwd       = pwd
            pdb_code  = pdb.basename(".pdb")
            pdb_obj   = Bio::PDB.new(IO.read(pdb))
            work_dir  = configatron.naccess_dir + pdb_code

            if (pdb_obj.models.first.aa_chains.empty? ||
                pdb_obj.models.first.na_chains.empty?)
              $logger.warn "Skip, #{pdb}: no amino acid chain nor nucleic acid chain"
              next
            end

            mkdir work_dir
            chdir work_dir

            co_pdb = "#{pdb_code}_co.pdb"

            File.open(co_pdb, "w") do |f|
              pdb_obj.models.first.aa_chains.each { |c| f.puts c.to_s }
              pdb_obj.models.first.na_chains.each { |c| f.puts c.to_s }
              f.puts "END\n"
            end

            aa_pdb = "#{pdb_code}_aa.pdb"

            File.open(aa_pdb, "w") do |f|
              pdb_obj.models.first.aa_chains.each { |c| f.puts c.to_s }
              f.puts "END\n"
            end

            na_pdb = "#{pdb_code}_na.pdb"

            File.open(na_pdb, "w") do |f|
              pdb_obj.models.first.na_chains.each { |c| f.puts c.to_s }
              f.puts "END\n"
            end

            system "#{configatron.naccess_bin} #{co_pdb} -h -r #{configatron.naccess_vdw} -s #{configatron.naccess_std}"
            system "#{configatron.naccess_bin} #{aa_pdb} -h -r #{configatron.naccess_vdw} -s #{configatron.naccess_std}"
            system "#{configatron.naccess_bin} #{na_pdb} -h -r #{configatron.naccess_vdw} -s #{configatron.naccess_std}"

            cp Dir["#{pdb_code}*"], ".."
            chdir cwd
            rm_r work_dir

            $logger.info "Running 'naccess' with #{pdb} (#{i + 1}/#{pdbs.size}): done"
          end
        end
      end
    end


    desc "Run DSSP on each PDB file"
    task :dssp => [:environment] do

      refresh_dir configatron.dssp_dir

      fm    = ForkManager.new(configatron.max_fork)
      pdbs  = Dir[configatron.pdb_dir + "*.pdb"].to_pathnames

      fm.manage do
        pdbs.each_with_index do |pdb, i|
          fm.fork do
            cwd = pwd
            chdir configatron.dssp_dir
            pdb_code = pdb.basename('.pdb')
            system "#{configatron.dssp_bin} #{pdb} 1> #{pdb_code}.dssp 2> #{pdb_code}.dssp.err"
            chdir cwd
            $logger.info "Running 'dsspcmbi' with #{pdb} (#{i + 1}/#{pdbs.size}): done"
          end
        end
      end
    end


    desc "Run OESpicoli and OEZap for unbound state PDB structures"
    task :spicoli => [:environment] do

      refresh_dir configatron.spicoli_dir

      fm    = ForkManager.new(configatron.max_fork)
      pdbs  = Dir[configatron.naccess_dir.join("*a.pdb")].to_pathnames

      fm.manage do
        pdbs.each_with_index do |pdb, i|
          bsn = pdb.basename(".pdb")
          pot = configatron.spicoli_dir + "#{bsn}.pot"
          fm.fork do
            system "#{configatron.spicoli_bin} #{pdb} 1> #{pot}"
            $logger.info "Running 'spicoli' with #{pdb} (#{i+1}/#{pdbs.size}): done"
          end
        end
      end
    end


    desc "Run 'TMalign' to create nucleic acid-binding chain families"
    task :tmalign => [:environment] do

      dir = configatron.tmalign_dir + "chains"
      refresh_dir dir

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do
        %w[dna rna].each do |na|
          # Generate chain PDB files
          AaChain.find_each do |chain|
            file = dir + "#{chain.fasta_header}_#{chain.chain_code}.pdb"
            file.open('w') do |f|
              f.puts chain.to_pdb
            end
          end
        end
      end

    end


    desc "Run 'cd-hit' for each PDB chains"
    task :cdhit_chains => [:environment] do

      %w[dna rna].each do |na|
        # Create FASTA files
        dir = configatron.cdhit_dir + "pdb" + na
        refresh_dir dir
        fasta = dir + "#{na}_binding_chains.fa"
        fasta.open('w') do |file|
          AaChain.find_each do |chain|
            hdr = chain.fasta_header

            if chain.send("#{na}_binding_residues").size > 0
              begin
                seq = chain.res_seq
                if (seq.count('X') / seq.length.to_f) < 0.5
                  file.puts ">#{hdr}"
                  file.puts seq
                  #$logger.info "Getting fasta from #{hdr}: done"
                else
                  #$logger.info "Skipped #{hdr}: "
                end
              rescue Exception => e
                $logger.error "Something wrong with #{hdr}: #{e}"
              end
            else
              #$logger.debug "Skipped #{hdr}: no #{na.upcase}-binding residues"
            end
          end
        end

        stem  = fasta.basename('.fa').to_s
        #cmd   = [
          #"blastclust",
          #"-i #{fasta}",
          #"-o #{dir.join(stem + '.nr100')}",
          #"-L .9",
          #"-S 100",
          #"-a 2",
          #"-p T",
          #"1> #{dir + 'blastclust.stdout'}",
          #"2> #{dir + 'blastclust.stderr'}",
        #].join(' ')

        cmd   = [
          "cd-hit",
          "-i #{fasta}",
          "-o #{dir.join(stem + '.nr100')}",
          "-c 1.0",
          "-s 0.9",
          "-n 5",
          "1> #{dir + 'cdhit.stdout'}",
          "2> #{dir + 'cdhit.stderr'}",
        ].join(' ')

        system cmd
        $logger.info "Running 'cd-hit' with #{fasta}: done"
      end
    end


    desc "Run 'cd-hit' for each SCOP family"
    task :cdhit_domains => [:environment] do

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do
        dir = configatron.cdhit_dir + "scop"
        refresh_dir dir

        %w[dna rna].each do |na|
          ScopFamily.send(:"reg_#{na}").find_each do |fam|
            sunid   = fam.sunid
            fam_dir = dir.join(na, sunid.to_s)

            mkdir_p fam_dir

            fasta = fam_dir + "#{sunid}.fa"
            fasta.open('w') do |file|
              doms = fam.leaves.select(&:"reg_#{na}")
              doms.each do |dom|
                seq = dom.to_sequence
                if (seq.count('X') / seq.length.to_f) < 0.5
                  file.puts ">#{dom.sunid}"
                  file.puts seq
                end
              end
            end

            ActiveRecord::Base.remove_connection
            fm.fork do
              if File.size? fasta
                stem  = fasta.basename('.fa').to_s
                #cmd   = [
                  #"blastclust",
                  #"-i #{fasta}",
                  #"-o #{fam_dir.join(stem + '.nr100')}",
                  #"-L .9",
                  #"-S 100",
                  #"-a 2",
                  #"-p T",
                  #"1> #{fam_dir + 'blastclust.stdout'}",
                  #"2> #{fam_dir + 'blastclust.stderr'}",
                #].join(' ')
                cmd   = [
                  "cd-hit",
                  "-i #{fasta}",
                  "-o #{fam_dir.join(stem + '.nr100')}",
                  "-c 1.0",
                  "-s 0.9",
                  "-n 5",
                  "1> #{fam_dir + 'cdhit.stdout'}",
                  "2> #{fam_dir + 'cdhit.stderr'}",
                ].join(' ')

                system cmd
                $logger.info "Run 'cd-hit' with #{na.upcase}-binding SCOP family, #{sunid}: done"
              end
            end
            ActiveRecord::Base.establish_connection
          end
        end
      end
    end


    namespace :salign do

      desc "Run SALIGN for representative PDB files for each SCOP Family"
      task :rep_scop_pdbs => [:environment] do

        fm = ForkManager.new(configatron.max_fork)
        fm.manage do
          %w[dna rna].each do |na|
            sunids  = ScopFamily.send("reg_#{na}").map(&:sunid).sort
            conn    = ActiveRecord::Base.remove_connection

            sunids.each_with_index do |sunid, i|
              fm.fork do
                cwd     = pwd
                cnt     = "(#{i+1}/#{sunids.size})"
                fam_dir = configatron.family_dir.join("scop", "rep", na, sunid.to_s)
                pdbs    = Pathname.glob(fam_dir.join("*.pdb")).map { |p| p.basename }

                if pdbs.size < 2
                  $logger.warn "Skipped #{na.upcase}-binding SCOP family, #{sunid} #{cnt}: only #{pdbs.size} PDB structure detected"
                  next
                end

                chdir fam_dir

                ## single linkage clustering using TM-score
                #clsts = Bipa::Tmalign.single_linkage_clustering(pdbs.combination(1).to_a)
                #clsts.each_with_index do |grp, gi|
                  #if grp.size < 2
                    #$logger.warn "Only #{grp.size} PDB structure detected in group, #{gi} in #{fam_dir}"
                    #next
                  #end

                  #system "salign #{grp.join(' ')} 1>salign#{gi}.stdout 2>salign#{gi}.stderr"
                  #mv "salign.ali", "salign#{gi}.ali"
                  #mv "salign.pap", "salign#{gi}.pap"
                  #$logger.info "SALIGN with group, #{gi} from representative set of #{na.upcase}-binding SCOP family, #{sunid} #{cnt}: done"
                #end

                # run salign without pre-clustering using TMAlign
                system "salign *.pdb 1>salign.stdout 2>salign.stderr"
                $logger.info "SALIGN with representative PDB files of #{na.upcase}-binding SCOP family, #{sunid} #{cnt}: done"
                chdir cwd
              end
            end
            ActiveRecord::Base.establish_connection(conn)
          end
        end
      end


      desc "Run SALIGN for each subfamilies of SCOP families"
      task :sub_scop_pdbs => [:environment] do

        fm = ForkManager.new(configatron.max_fork)
        fm.manage do
          %w[dna rna].each do |na|
            sunids = ScopFamily.send("reg_#{na}").map(&:sunid).sort
            config = ActiveRecord::Base.remove_connection

            sunids.each do |sunid|
              cwd     = pwd
              famdir  = configatron.family_dir.join("scop/sub", na, sunid.to_s)

              Dir[famdir.join("*")].each do |subfamdir|
                pdbs = Dir[File.join(subfamdir, "*.pdb")]

                if pdbs.size < 2
                  $logger.warn "Only #{pdbs.size} PDB structure detected in #{subfamdir}"
                  next
                end

                if File.size?(File.join(subfamdir, "salign.ali")) and File.size?(File.join(subfamdir, "salign.pap"))
                  $logger.warn "Skipped #{subfamdir}"
                  next
                end

                chdir subfamdir

                fm.fork do
                  system "salign *.pdb 1>salign.stdout 2>salign.stderr"
                end

                chdir cwd
              end
              $logger.info "SALIGN with subfamilies of #{na.upcase}-binding SCOP family, #{sunid}: done"
            end
            ActiveRecord::Base.establish_connection(config)
          end
        end
      end

    end # namespace :salign

    namespace :mafft do

      desc "Run MAFFT for each subfamilies of SCOP families"
      task :sub_scop_pdbs => [:environment] do

        fm = ForkManager.new(configatron.max_fork)
        fm.manage do
          %w[dna rna].each do |na|
            sunids = ScopFamily.send("reg_#{na}").map(&:sunid).sort
            config = ActiveRecord::Base.remove_connection

            sunids.each do |sunid|
              fm.fork do
                cwd     = pwd
                famdir  = configatron.family_dir.join("scop", "sub", na, sunid.to_s)

                famdir.children.select(&:directory?).each do |subfamdir|
                  pdbs = Pathname.glob(subfamdir.join("*.pdb")).map(&:basename)

                  if pdbs.size < 2
                    $logger.warn "Only #{pdbs.size} PDB structure detected in #{subfamdir}"
                    next
                  end

                  chdir subfamdir

                  # create one big fasta file
                  fasta = subfamdir + "msa_input.fasta"
                  fasta.open("w") do |file|
                    pdbs.each do |pdb|
                      str = Bio::PDB.new(IO.read(pdb))
                      seq = str.models.first.chains.map(&:atom_seq).join("/")
                      hdr = ">#{pdb.basename(".pdb").to_s}"
                      file.puts hdr
                      file.puts seq
                    end
                  end

                  system "muscle -msf -in msa_input.fasta -out msa.msf 1>muscle.stdout 2>muscle.stderr"
                  system "mview -in msf -out pir msa.msf > msa.pir"

                  mod_ali = subfamdir + "msa.ali"
                  mod_ali.open("w") do |file|
                    Bio::FlatFile.auto("msa.pir").each_entry do |ent|
                     ent.entry_id.gsub!(/^\d+;/, "")
                     ent.definition = "structureX:#{ent.entry_id}"
                     file.puts ent
                    end
                  end

                  system "joy msa.ali 1>joy.stdout 2>joy.stderr"

                  chdir cwd
                end
              end
              $logger.info "MUSCLE with subfamilies of #{na.upcase}-binding SCOP family, #{sunid}: done"
            end
            ActiveRecord::Base.establish_connection(config)
          end
        end
      end

    end

    namespace :baton do

      desc "Run Baton for each SCOP family"
      task :all_scop_pdbs => [:environment] do

        %w[dna rna].each do |na|
          sunids    = ScopFamily.send("reg_#{na}").map(&:sunid).sort
          all_dir  = File.join(configatron.family_dir, "all", na)
          fm  = ForkManager.new(configatron.max_fork)

          fm.manage do
            config = ActiveRecord::Base.remove_connection

            sunids.each_with_index do |sunid, i|
              fm.fork do
                ActiveRecord::Base.establish_connection(config)
                cwd       = pwd
                fam_dir   = File.join(all_dir, sunid.to_s)
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
                $logger.info ">>> Baton with all set of #{na.upcase}-binding SCOP family, #{sunid}: done (#{i + 1}/#{sunids.size})"
                ActiveRecord::Base.remove_connection
              end
            end
            ActiveRecord::Base.establish_connection(config)
          end
        end
      end


      desc "Run Baton for representative PDB files for each SCOP Family"
      task :rep_scop_pdbs => [:environment] do

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
      task :sub_scop_pdbs => [:environment] do

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
      task :scop_rep_alignments => [:environment] do

        #$logger.level = Logger::ERROR

        fm = ForkManager.new(configatron.max_fork)
        fm.manage do
          %w[dna rna].each do |na|
            cwd       = pwd
            fam_dirs  = Pathname.glob(configatron.family_dir.join("scop", "rep", na, "*"))

            fam_dirs.each do |fam_dir|
              chdir fam_dir
              align = fam_dir + "salign.ali"

              if !align.exist?
                $logger.warn "Cannot find alignment file, 'salign.ali' in #{fam_dir}"
                pdbs = Pathname.glob(fam_dirs + "*.pdb")

                if pdbs.size == 1
                  $logger.warn "Run JOY for a single protein, #{pdbs[0]} instead ..."

                  pdb   = pdbs[0].cleanpath
                  sunid = pdb.basename(".pdb").to_s
                  tem   = sunid + ".tem"
                  fm.fork do
                    system "joy #{pdb} 1>joy.stdout 2>joy.stderr"
                    if tem.exist?
                      cp(pdb, 'single.tem')
                    else
                      $logger.error "JOY failed to run with #{pdb} in #{fam_dir}"
                    end
                  end
                elsif pdbs.size > 1
                  $logger.error "#{fam_dir} has two or more structures! Why no 'salign.ali' here?"
                  exit 1
                elsif pdbs.size == 0
                  $logger.error "#{fam_dir} has no structures!"
                  exit 1
                end
              else
                modali  = Pathname.new("modsalign.ali")
                tem     = Pathname.new("modsalign.tem")
                modali.open("w") { |f| f.puts IO.read(align).gsub(/\.pdb/, "") }

                fm.fork do
                  system "joy #{modali.to_s} 1>joy.stdout 2>joy.stderr"
                  if !tem.exist?
                    $logger.error "JOY failed to run with #{modali} in #{fam_dir}"
                  end
                end
              end
            $logger.info "JOY with an alignment in #{fam_dir}: done"
            end
          end
        end
      end


      desc "Run JOY for SCOP subfamily alignments"
      task :scop_sub_alignments => [:environment] do

        $logger.level = Logger::ERROR

        fm = ForkManager.new(configatron.max_fork)
        fm.manage do
          %w[dna rna].each do |na|
            cwd         = pwd
            subfam_dirs = Pathname.new(configatron.family_dir.join("scop", "sub", na, "*", "*").to_s)

            subfam_dirs.each do |subfam_dir|
              ali = subfam_dir + "msa.ali"

              if !ali.exist?
                $logger.warn "Cannot find an alignment file, msa.ali in #{subfam_dir}"
                next
              end

              chdir subfam_dir
              modali  = Pathname.new("modmsa.ali")
              tem     = Pathname.new("modmsa.tem")

              modali.open("w") { |f| f.puts IO.read(ali).gsub(/\.pdb/, "") }

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

                if !tem.exist?
                  $logger.error "JOY failed to run with #{modali} in #{subfam_dir}"
                end
              end

              chdir cwd
              $logger.info "JOY with an alignment in #{subfam_dir}: done"
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
    task :usr => [:environment] do

      [DomainNucleicAcidInterface, ChainNucleicAcidInterface].each do |klass|
        usr_bin = configatron.usr_bin
        usr_des = "./tmp/#{klass.to_s.downcase}_descriptors.txt"
        usr_res = "./tmp/#{klass.to_s.downcase}_descriptor_similarities.txt"
        usr_cmd = "#{usr_bin} < #{usr_des} > #{usr_res}"
        system usr_cmd
        $logger.info "Running 'usr' with #{usr_res}: done"
      end
    end
  end


  namespace :fuguena do

    desc "Run Ulla to generate ESSTs"
    task :ulla => [:environment] do

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do
        %w[dna rna].each do |na|
          #["ord64", "std64", "#{na}128", "#{na}256"].each do |env|
          ["ord64"].each do |env|
            fm.fork do
              cwd      = pwd
              esstdir  = configatron.fuguena_dir.join("essts", na, env)

              mkdir_p esstdir
              chdir   esstdir

              cp configatron.fuguena_dir.join("classdef.#{env}"), "classdef.dat"

              modtems = Dir[configatron.family_dir.join("rep", na, "*", "#{na}modsalign*.tem").to_s]
              newtems = []

              modtems.each do |modtem|
                if modtem =~ /(\d+)\/#{na}modsalign(\d+)\.tem/
                  stem    = "#{$1}_#{$2}"
                  newtem  = esstdir.join("#{stem}.tem")
                  newtems << stem
                  cp modtem, newtem
                end
              end

              newtems.each do |newtem|
                mkdir_p newtem
                chdir   newtem

                if env == "ord64"
                  cp configatron.fuguena_dir.join("subst-ord64-60.lgd"), "."
                else
#                  system "ls -1 ../*.tem | grep -v #{newtem} > temfiles.lst"
#
#                  (30..100).step(10) do |weight|
#                    system "ulla -l temfiles.lst -c ../classdef.dat --autosigma --weight #{weight} --output 2 -o ulla-#{env}-#{weight}.lgd"
#                  end
                end
                chdir esstdir
              end
              chdir cwd
              $logger.info "Running ulla in #{esstdir}: done"
            end
          end
        end
      end
    end


    desc "Run Melody for representative sets of protein-DNA/RNA complex"
    task :melody => [:environment] do

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do
        %w[dna rna].each do |na|
          #["ord64", "std64", "#{na}128", "#{na}256"].each do |env|
          ["ord64"].each do |env|
            fm.fork do
              cwd     = pwd
              esstdir = configatron.fuguena_dir.join("essts", na, env)
              tests   = esstdir.children.select { |c| c.directory? }

              tests.each do |test|
                chdir test
                fam     = test.basename
                bff     = Bio::FlatFile.auto("../#{fam}.tem")
                sunids  = []

                bff.each_entry { |e| sunids << e.entry_id if e.definition == 'sequence' }

                sunids.each do |sunid|
                  bff.rewind
                  tem = "#{sunid}.tem"
                  File.open(tem, "w") do |file|
                    bff.each_entry do |entry|
                      if entry.entry_id == sunid
                        file.puts ">P1;#{entry.entry_id}"
                        file.puts "#{entry.definition}"
                        file.puts "#{entry.data.gsub(/[\n|\-]/, '')}*"
                      end
                    end
                  end
                  mat = (env == "ord64" ? "subst-ord64-60.lgd" : "ulla-#{env}-60.lgd")
                  system "melody -t #{tem} -c ../classdef.dat -s #{mat} -o #{fam}-#{sunid}-#{env}-60.fug"
                end
              end
              chdir cwd
              $logger.info "Run melody in #{esstdir}: done"
            end
          end
        end
      end
    end


    desc "Run FUGUE for representative sets of protein-DNA/RNA complex"
    task :fugue => [:environment] do

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do
        %w[dna rna].each do |na|
          #["ord64", "std64", "#{na}128", "#{na}256"].each do |env|
          ["ord64"].each do |env|
            cwd   = pwd
            tests = configatron.fuguena_dir.join("essts", na, env).children.select { |c| c.directory? }
            total = tests.size

            tests.each_with_index do |test, i|
              chdir test
              fugs  = test.children.select { |c| c.extname == '.fug' }
              s40   = configatron.fuguena_dir + "astral40.fa"

              fugs.each do |fug|
                stem = fug.basename(".fug")
                cmd =   "fugueprf " +
                          "-seq #{s40} " +
                          "-prf #{fug} " +
                          "-allrank " +
                          "-o fugue-#{stem}.seq " +
                          "> fugue-#{stem}.hits"
                fm.fork do
                  system cmd
                end
              end
              chdir cwd
              $logger.info "FUGUE-#{na.upcase}-#{env} search in #{test}: done (#{i+1}/#{total})"
            end
          end
        end
      end
    end


    desc "Run Needle for representative sets of protein-DNA/RNA complex"
    task :needle => [:environment] do

      refresh_dir(configatron.needle_dir)

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do
        %w[dna rna].each do |na|
          cwd   = pwd
          nadir = configatron.needle_dir + na
          s40   = configatron.fuguena_dir + "astral40.fa"

          mkdir_p nadir
          chdir   nadir

          tems = Dir[configatron.fuguena_dir.join("essts", na, "std64", "*", "*.tem").to_s]
          tems.each_with_index do |tem, i|
            fm.fork do
              stem  = File.basename(tem, '.tem')
              fa    = "#{stem}.fa"
              ndl   = "#{stem}.ndl"
              bff   = Bio::FlatFile.auto(tem)

              bff.each_entry do |entry|
                if entry.definition == 'sequence'
                  File.open(fa, 'w') do |file|
                    file.puts ">#{entry.entry_id}"
                    file.puts "#{entry.data}"
                  end
                  cmd = "needle -asequence #{fa} -bsequence #{s40} -gapopen 10.0 -gapextend 0.5 -auto -aformat3 score -outfile #{ndl}"
                  system cmd
                  $logger.info "Needleman-Wunsch (#{na.upcase} set) search for #{fa}: done (#{i+1}/#{tems.size})"
                end
              end
            end
          end
          chdir cwd
        end
      end
    end


    desc "Run Water for representative sets of protein-DNA/RNA complex"
    task :water => [:environment] do

      refresh_dir(configatron.water_dir)

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do
        %w[dna rna].each do |na|
          cwd   = pwd
          nadir = configatron.water_dir + na
          s40   = configatron.fuguena_dir + "astral40.fa"

          mkdir_p nadir
          chdir   nadir

          tems = Dir[configatron.fuguena_dir.join("essts", na, "std64", "*", "*.tem").to_s]
          tems.each_with_index do |tem, i|
            fm.fork do
              stem  = File.basename(tem, '.tem')
              fa    = "#{stem}.fa"
              ndl   = "#{stem}.smw"
              bff   = Bio::FlatFile.auto(tem)

              bff.each_entry do |entry|
                if entry.definition == 'sequence'
                  File.open(fa, 'w') do |file|
                    file.puts ">#{entry.entry_id}"
                    file.puts "#{entry.data}"
                  end
                  cmd = "water -asequence #{fa} -bsequence #{s40} -gapopen 10.0 -gapextend 0.5 -auto -aformat3 score -outfile #{ndl}"
                  system cmd
                  $logger.info "Smith & Watermann (#{na.upcase} set) search for #{fa}: done (#{i+1}/#{tems.size})"
                end
              end
            end
          end
          chdir cwd
        end
      end
    end


    desc "Run PSI-Blast for representative sets of protein-DNA/RNA complex"
    task :psiblast => [:environment] do

      refresh_dir(configatron.psiblast_dir)

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do
        %w[dna rna].each do |na|
          cwd   = pwd
          nadir = configatron.psiblast_dir + na
          nr    = configatron.fuguena_dir + "uniref90_astral40.fa"

          mkdir_p nadir
          chdir   nadir

          tems = Dir[configatron.fuguena_dir.join("essts", na, "std64", "*", "*.tem").to_s]
          tems.each_with_index do |tem, i|
            fm.fork do
              stem  = File.basename(tem, '.tem')
              fa    = "#{stem}.fa"
              xml   = "#{stem}.xml"
              bff   = Bio::FlatFile.auto(tem)

              bff.each_entry do |entry|
                if entry.definition == 'sequence'
                  File.open(fa, 'w') do |file|
                    file.puts ">#{entry.entry_id}"
                    file.puts "#{entry.data}"
                  end
                  cmd = "blastpgp -i #{fa} -d #{nr} -j 5 -m 7 -o #{xml}"
                  system cmd
                  $logger.info "PSI-Blast (#{na.upcase} set) search for #{fa}: done (#{i+1}/#{tems.size})"
                end
              end
            end
          end
          chdir cwd
        end
      end
    end


    desc "Run FUGUEALI for representative sets of protein-DNA/RNA complex"
    task :fugueali => [:environment] do
    end

  end
end
