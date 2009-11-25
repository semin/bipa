namespace :fuguena do
  namespace :generate do

    desc "Generate prediction tables from FUGUE-NA results"
    task :pred_fugue => [:environment] do

      $logger.debug "Constructing SCOP matching hash table ..."

      sid_to_sunid          = {}
      sunid_to_sid          = {}
      sunid_to_sccs         = {}
      sunid_to_supfam_sunid = {}

      ScopDomain.all.each do |dom|
        sid_to_sunid[dom.sid]             = dom.sunid
        sunid_to_sid[dom.sunid]           = dom.sid
        sunid_to_sccs[dom.sunid]          = dom.sccs
        sunid_to_supfam_sunid[dom.sunid]  = dom.scop_superfamily.sunid
      end

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do
        %w[dna rna].each do |na|
          #["ord64", "std64", "#{na}128", "#{na}256"].each do |env|
          ["ord64"].each do |env|
            (60..60).step(10) do |weight|

              fm.fork do
                esstdir = configatron.fuguena_dir.join("essts", na, env)
                famdirs = esstdir.children.select { |d| d.directory? }

                famdirs.each_with_index do |famdir, i|
                  pred_table = esstdir.join("fugue-pred-#{na}-#{env}-#{weight}-#{famdir.basename}.csv")
                  pred_table.open('w') do |file|
                    hit_files = Dir[famdir.join("fugue-#{famdir.basename}-*-#{env}-#{weight}.hits").to_s]
                    hit_files.each do |hit_file|
                      qsunid      = File.basename(hit_file).split('-')[2].to_i
                      qsccs       = sunid_to_sccs[qsunid]
                      qsid        = sunid_to_sid[qsunid]
                      qsfam_sunid = sunid_to_supfam_sunid[qsunid]

                      IO.readlines(hit_file).each do |line|
                        if line.blank?
                          next
                        elsif line.start_with?("#")
                          next
                        else
                          # Sequence           SLEN  RAWS RVN  ZSCORE   PVZ     ZORI    EVP     EVF   AL#
                          # d1twfa_ e.29.1.2... 1449 14441 15476  302.47 1.0E+03  302.33 1.0E+03 1.0E+03 0
                          # d2enda_ a.18.1.1...  137  1385 1475   66.98 1.0E+03   66.84 1.0E+03 1.0E+03 0
                          # d2hc5a1 d.352.1....  109  -257  45    1.01 1.0E+03    2.07 1.0E+03 1.0E+03 0
                          seq         = line[1..19].strip
                          (len, raws, rvn, zscore) = line[20..line.length].strip.split(/\s+/)
                          tsid        = seq.match(/^(\S+)\s+/)[1].gsub(/^g/, 'd')
                          tsunid      = sid_to_sunid[tsid]
                          tsccs       = sunid_to_sccs[tsunid]
                          tsfam_sunid = sunid_to_supfam_sunid[tsunid]
                          tag         = qsfam_sunid == tsfam_sunid ? 1 : -1
                          cols        = [tag, zscore, qsid, qsccs, tsid, tsccs, len, raws, rvn]

                          file.puts cols.join(", ")
                        end
                      end
                    end
                  end
                  $logger.info "Processing #{famdir}: done"
                end
              end # fm.fork
            end
          end
        end
        ActiveRecord::Base.establish_connection(conn)
      end # fm.manage
    end


    desc "Generate prediction tables from needle results"
    task :pred_needle => [:environment] do

      $logger.debug "Constructing SCOP matching hash table ..."

      sid_to_sunid          = {}
      sunid_to_sid          = {}
      sunid_to_sccs         = {}
      sunid_to_supfam_sunid = {}

      ScopDomain.all.each do |dom|
        sid_to_sunid[dom.sid]             = dom.sunid
        sunid_to_sid[dom.sunid]           = dom.sid
        sunid_to_sccs[dom.sunid]          = dom.sccs
        sunid_to_supfam_sunid[dom.sunid]  = dom.scop_superfamily.sunid
      end

      %w[dna rna].each do |na|
        ndldir  = configatron.needle_dir
        nadir   = ndldir + na
        ndls    = Dir[nadir.join('*.ndl').to_s].map { |f| Pathname.new(f) }
        rank    = ndldir + "needle-pred-#{na}.csv"
        hits    = []

        rank.open('w') do |file|
          ndls.each do |ndl|
            qsunid  = ndl.basename('.ndl').to_s.to_i
            qsid    = sunid_to_sid[qsunid]
            qsccs   = sunid_to_sccs[qsunid]
            #query   = ScopDomain.find_by_sunid(qsunid)
            #qsfam   = query.scop_superfamily

            ndl.each_line do |line|
              if ((columns = line.chomp.split(/\s+/)).size == 4)
                tsid    = columns[1].gsub(/^g/, 'd')
                score   = columns[3].gsub(/[\(|\)]/, '')
                tsunid  = sid_to_sunid[tsid]
                tsccs   = sunid_to_sccs[tsunid]
                #target  = ScopDomain.find_by_sid(tsid)
                #tsfam   = target.scop_superfamily
                #tag     = qsfam.sunid == tsfam.sunid ? 1 : -1
                tag     = sunid_to_supfam_sunid[qsunid] == sunid_to_supfam_sunid[tsunid] ? 1 : -1
                #cols    = [ tag, score, query.sunid, query.sid, query.sccs, target.sid, target.sunid, target.sccs ]
                cols    = [ tag, score, qsunid, qsid, qsccs, tsid, tsunid, tsccs ]
                file.puts cols.join(", ")
              end
            end
            $logger.info "Processing #{ndl}: done"
          end
        end
      end
    end


    desc "Generate a ROC table from PSI-BLAST results"
    task :roc_needle => [:environment] do

      %w[dna rna].each do |na|
        pred    = configatron.needle_dir + "needle-pred-#{na}.csv"
        pred50  = configatron.needle_dir + "needle-pred50-#{na}.csv"
        roc     = configatron.needle_dir + "needle-roc-#{na}.csv"
        hits    = []

        pred.each_line do |line|
          hits << line.chomp.split(", ") if !line.blank?
        end

        true_pos  = 0
        false_pos = 0
        tf_pairs  = []
        tf_pairs  << [false_pos, true_pos]

        pred50.open('w') do |file|
          sorted_hits = hits.sort { |a, b| Float(b[1]) <=> Float(a[1]) }
          sorted_hits.each do |hit|
            if Integer(hit[0]) == 1
              true_pos += 1
            elsif Integer(hit[0]) == -1
              false_pos += 1
            end
            tf_pairs << [false_pos, true_pos]
            file.puts hit.join(", ") if false_pos <= 50
          end
        end

        roc.open('w') { |f| tf_pairs.each { |p| f.puts p.join(", ") } }
      end
    end


    desc "Generate prediction tables from PSI-BLAST results"
    task :pred_psiblast => [:environment] do

      %w[dna rna].each do |na|
        psidir  = configatron.psiblast_dir
        nadir   = psidir + na
        xmls    = Dir[nadir.join('*.xml').to_s]
        rank    = psidir + "psiblast-pred-#{na}.csv"
        hits    = []

        rank.open('w') do |file|
          xmls.each do |xml|
            Bio::Blast.reports(File.open(xml)) do |report|
              query = ScopDomain.find_by_sunid(report.query_def)
              qsfam = query.scop_superfamily

              report.each do |hit|
                tsid    = hit.target_def.match(/^(\S+)/)[1].gsub(/^g/, 'd')
                target  = ScopDomain.find_by_sid(tsid)
                tsfam   = target.scop_superfamily
                tag     = qsfam.sunid == tsfam.sunid ? 1 : -1
                columns = [ tag, hit.evalue, hit.bit_score, query.sunid, query.sid, query.sccs, target.sid, target.sunid, target.sccs ]
                file.puts columns.join(", ")
              end
            end
          end
        end
      end
    end


    desc "Generate ROC tables for FUGUE search"
    task :roc_fugue => [:environment] do

#      fm = ForkManager.new(configatron.max_fork)
#      fm.manage do
#        conn = ActiveRecord::Base.remove_connection

        %w[dna rna].each do |na|
          #["ord64", "std64", "#{na}128", "#{na}256"].each do |env|
          ["ord64"].each do |env|
            (60..60).step(10) do |weight|

#              fm.fork do
#                ActiveRecord::Base.establish_connection(conn)
                total_hits  = []
                esstdir     = configatron.fuguena_dir.join("essts", na, env)
                pred_tables = Dir[esstdir.join("fugue-pred-#{na}-#{env}-#{weight}-*.csv").to_s]
                pred_tables.each do |pred_table|

                  # Check if the prediction file belongs to true SCOP classes
                  bname = File.basename(pred_table, ".csv")
                  sunid = bname.split("-")[5].split("_")[0]
                  sfam  = ScopFamily.find_by_sunid(sunid)

                  if (sfam.sccs !~ /^[a|b|c|d|e|f|g]/)
                    $logger.warn "Skip, #{bname}.csv: #{sunid} (#{sfam.sccs}) does NOT belong to a true SCOP class!"
                    next
                  end

                  hits = []

                  IO.readlines(pred_table).each do |line|
                    hits        << line.chomp.split(", ") unless line.blank?
                    total_hits  << line.chomp.split(", ") unless line.blank?
                  end

#                  sorted_hits = hits.sort { |a, b| Float(b[1]) <=> Float(a[1]) }
#                  sorted_pred = esstdir + pred_table.sub("pred", "sorted")
#                  true_pos    = 0
#                  false_pos   = 0
#                  tf_pairs    = []
#                  tf_pairs    << [false_pos, true_pos]
#
#                  sorted_pred.open('w') do |file|
#                    sorted_hits.each do |hit|
#                      if Integer(hit[0]) == 1
#                        true_pos += 1
#                      elsif Integer(hit[0]) == -1
#                        false_pos += 1
#                      end
#                      tf_pairs << [false_pos, true_pos]
#                      file.puts hit.join(", ")
#                    end
#                  end
#
#                  [10, 20, 50].each do |cut|
#                    roc_table = esstdir + pred_table.sub("pred", "roc#{cut}")
#                    roc_table.open('w') do |file|
#                      tf_pairs.each_with_index do |pair, i|
#                        begin
#                          file.puts sorted_hits[i].join(', ') if pair[0] < cut
#                        rescue
#                          raise "Error: you should check the row, #{i+1} in #{sorted_pred}"
#                        end
#                      end
#                    end
#                  end

                  $logger.info "Processing #{bname}: done"
                end

                sorted_hits = total_hits.sort { |a, b| Float(b[1]) <=> Float(a[1]) }
                sorted_pred = esstdir + "fugue-total-sorted-#{na}-#{env}-#{weight}.csv"
                true_pos    = 0
                false_pos   = 0
                tf_pairs    = []
                tf_pairs    << [false_pos, true_pos]

                sorted_pred.open('w') do |file|
                  sorted_hits.each do |hit|
                    if Integer(hit[0]) == 1
                      true_pos += 1
                    elsif Integer(hit[0]) == -1
                      false_pos += 1
                    end
                    tf_pairs << [false_pos, true_pos]
                    file.puts hit.join(", ")
                  end
                end

                [10, 20, 50].each do |cut|
                  #roc_table = esstdir + "fugue-tot#{cut}-#{na}-#{env}-#{weight}.csv"
                  roc_table = esstdir + "fugue-cnt#{cut}-#{na}-#{env}-#{weight}.csv"
                  roc_table.open('w') do |file|
                    tf_pairs.each_with_index do |pair, i|
                      #file.puts sorted_hits[i].join(', ') if pair[0] < cut
                      file.puts pair.join(", ") if pair[0] < cut
                    end
                  end
                end

#                ActiveRecord::Base.remove_connection
#              end # fm.fork
            end
          end
        end
#        ActiveRecord::Base.establish_connection(conn)
#      end
    end


    desc "ROC curves from FUGUE results"
    task :r_fugue => [:environment] do

      %w[dna rna].each do |na|
        (60..60).step(10) do |weight|
          [10, 20, 50].each do |cut|
            envs    = ["std64", "#{na}128", "#{na}256"]
            esstdir = configatron.fuguena_dir + "essts"
            rfile   = esstdir + "fugue-#{na}-#{weight}-roc#{cut}.R"

            rfile.open('w') do |file|
              file.puts <<-R_CODE
library(ROCR)
              R_CODE

              envs.each_with_index do |env, env_index|
                roc_tables = Dir[esstdir.join(na, env, "fugue-roc#{cut}-#{na}-#{env}-#{weight}-*.csv").to_s].map { |d| Pathname.new(d) }
                roc_tables.each_with_index do |roc_table, roc_index|
                  file.puts <<-R_CODE
#{env}.#{roc_index} <- read.csv("#{roc_table.relative_path_from(esstdir)}", head=FALSE)
                  R_CODE
                end

                file.puts <<-R_CODE
#{env}.labels <- list(#{(0..roc_tables.size-1).map { |i| "#{env}.#{i}[,1]" }.join(", ") })
#{env}.predictions <- list(#{(0..roc_tables.size-1).map { |i| "#{env}.#{i}[,2]" }.join(", ") })
pred.#{env} <- prediction(#{env}.predictions, #{env}.labels)
perf.#{env} <- performance(pred.#{env}, 'tpr', 'fpr')
plot( perf.#{env}, lty=3, col=#{if (env_index == 0); "'red'";elsif (env_index == 1); "'blue'";else "'green'"; end} #{if (env_index != 0) then ', add=TRUE' end} )
plot( perf.#{env}, avg="vertical", lwd=3, col=#{if (env_index == 0); "'red'";elsif (env_index == 1); "'blue'";else "'green'"; end}, spread.estimate="stderror", plotCI.lwd=2, add=TRUE )
                R_CODE
              end

              file.puts <<-R_CODE
legend(0.6, 0.6, c(#{envs.map { |e| "'#{e}'"}.join(", ")}), col=c('red','blue','green'), lwd=3)
              R_CODE
            end

            $logger.info "Generating R codes for ROC#{cut} curves from #{na.upcase}-binding sets: done"
          end

        end
      end
    end

  end
end
