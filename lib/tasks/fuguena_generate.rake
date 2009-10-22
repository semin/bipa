namespace :fuguena do
  namespace :generate do

    desc "Generate ESSTs from representative sets of SCOP family alignments for FUGUE benchmark"
    task :essts => [:environment] do

      refresh_dir(configatron.esst_dir) unless configatron.resume

      scop40  = "/BiO/Store/SCOP/scopseq/astral-scopdom-seqres-gd-sel-gs-bib-40-1.75.fa"
      fm      = ForkManager.new(configatron.max_fork)

      fm.manage do
        %w[dna rna].each do |na|
          ["std64", "#{na}128", "#{na}256"].each do |env|
            fm.fork do
              cwd      = pwd
              esstdir  = configatron.esst_dir.join(na, env)

              mkdir_p esstdir
              chdir   esstdir

              cp Rails.root.join("config", "classdef.#{env}"), "classdef.dat"

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

                system "ls -1 ../*.tem | grep -v #{newtem} > temfiles.lst"

                (30..100).step(10) do |weight|
                  system "ulla -l temfiles.lst -c ../classdef.dat --autosigma --weight #{weight} --output 2 -o ulla-#{env}-#{weight}.lgd"
                  system "melody -t ../#{newtem}.tem -c ../classdef.dat -s ulla-#{env}-#{weight}.lgd -o #{newtem}-#{env}-#{weight}.fug"
                  #system "fugueprf -y -seq #{scop40} -prf #{newtem}-#{env}-#{weight}.fug -zrank 1.0 -o fugue-#{newtem}-#{env}-#{weight}.seq > fugue-#{newtem}-#{env}-#{weight}.hits"
                  system "fugueprf -seq #{scop40} -prf #{newtem}-#{env}-#{weight}.fug -allrank -o fugue-#{newtem}-#{env}-#{weight}.seq > fugue-#{newtem}-#{env}-#{weight}.hits"
                end

                chdir esstdir
              end

              chdir cwd
            end
          end
        end
      end
    end


    desc "Generate FUGUE profiles for each representative set of SCOP families"
    task :profiles => [:environment] do

      # Need to consider dividing Training/Testing set
      %w[dna rna].each do |na|
        ["std64", "#{na}128", "#{na}256"].each do |env|
          cwd     = pwd
          esstdir = File.join(configatron.esstdir, "rep#{si}", "#{na}#{env}")

          chdir esstdir
          cp "allmat.#{na}#{env}.log.dat", "allmat.dat.log"
          system "melody -list templates.lst -c classdef.dat -s allmat.dat.log"
          chdir cwd
        end
      end
    end


    desc "Generate a rank table for TF/TN/FT/FNs from FUGUE search"
    task :rank_tables => [:environment] do

      fmanager = ForkManager.new(configatron.max_fork)
      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        %w[dna rna].each do |na|
          ["std64", "#{na}128", "#{na}256"].each do |env|
            (30..100).step(10) do |weight|

              fmanager.fork do
                ActiveRecord::Base.establish_connection(config)

                esstdir     = configatron.esst_dir.join(na, env)
                famdirs     = esstdir.children.select { |d| d.directory? }
                rank_table  = esstdir.join("rank-#{na}-#{env}-#{weight}.csv")
                fugue_hits  = []

                rank_table.open('w') do |file|
                  famdirs.each do |famdir|
                    qfam_sunid  = famdir.basename.to_s.match(/^(\d+)\_(\d+)/)[1].to_i
                    qfam        = Scop.find_by_sunid(qfam_sunid)

    #                # Skip if it is not a true SCOP family!!!
    #                if qfam.sccs !~ /^[a|b|c|d|e|f|g]/
    #                  $logger.warn "Skipped #{famdir} (#{qfam.sccs}) as it's not a true SCOP family"
    #                  next
    #                end

                    hit_file = famdir.join("fugue-#{famdir.basename}-#{env}-#{weight}.hits")
                    hit_file.each_line do |line|
                      if line.blank?
                        next
                      elsif line.start_with?("#")
                        next
                      else
                        # Sequence           SLEN  RAWS RVN  ZSCORE   PVZ     ZORI    EVP     EVF   AL#
                        # d1twfa_ e.29.1.2... 1449 14441 15476  302.47 1.0E+03  302.33 1.0E+03 1.0E+03 0
                        # d2enda_ a.18.1.1...  137  1385 1475   66.98 1.0E+03   66.84 1.0E+03 1.0E+03 0
                        # d2hc5a1 d.352.1....  109  -257  45    1.01 1.0E+03    2.07 1.0E+03 1.0E+03 0
                        seq = line[1..19].strip
                        (len, raws, rvn, zscore) = line[20..line.length].strip.split(/\s+/)

                        tseq_sid    = seq.match(/^(\S+)\s+/)[1]
                        tseq_sid[0] = "d"
                        tfam        = Scop.find_by_sid(tseq_sid).scop_family

                        # Hits SCOP superfamily level
                        tag         = tfam.parent.sunid == qfam.parent.sunid ? "T" : "F"

                        # Hits SCOP family level
                        #tag         = tfam.sunid == qfam.sunid ? "T" : "F"
                        columns     = [tag, zscore, tseq_sid, tfam.sccs, tfam.sunid, qfam.sccs, qfam.sunid, len, raws, rvn]
                        fugue_hits  << columns

                        file.puts columns.join(", ")
                      end
                    end
                  end
                end

                ActiveRecord::Base.remove_connection

                true_pos  = 0
                false_pos = 0
                roc_table = esstdir.join("roc-#{na}-#{env}-#{weight}.csv")

                roc_table.open("w") do |file|
                  sorted_hits = fugue_hits.sort { |a, b| b[1] <=> a[1] }
                  sorted_hits.each do |hit|
                    if hit[0] == "T"
                      true_pos += 1
                    elsif hit[0] == "F"
                      false_pos += 1
                      file.puts [false_pos, true_pos].join(", ")
                    end
                  end
                end
              end # fmanager.fork

            end
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end # fmanager.manage
    end

  end
end
