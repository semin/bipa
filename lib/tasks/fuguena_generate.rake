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
        conn = ActiveRecord::Base.remove_connection

        %w[dna rna].each do |na|
          ["std64", "#{na}128", "#{na}256"].each do |env|
            (60..60).step(10) do |weight|

              fm.fork do
                ActiveRecord::Base.establish_connection(conn)
                esstdir = configatron.fuguena_dir.join("essts", na, env)
                famdirs = esstdir.children.select { |d| d.directory? }

                famdirs.each_with_index do |famdir, i|
                  pred_table = esstdir.join("fugue-pred-#{na}-#{env}-#{weight}-#{i+1}.csv")
                  pred_table.open('w') do |file|
                    #qfam_sunid  = famdir.basename.to_s.match(/^(\d+)\_\d+/)[1].to_i
                    #qfam        = ScopFamily.find_by_sunid(qfam_sunid)

                    ## Skip if it is not a true SCOP family!!!
                    #if qfam.sccs !~ /^[a|b|c|d|e|f|g]/
                    #  $logger.warn "Skipped #{famdir} (#{qfam.sccs}) as it's not a true SCOP family"
                    #  next
                    #end

                    hit_files = Dir[famdir.join("fugue-#{famdir.basename}-*-#{env}-#{weight}.hits").to_s]
                    hit_files.each do |hit_file|
                      qsunid = File.basename(hit_file).split('-')[2].to_i

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
                          #tfam  = ScopDomain.find_by_sid(tsid).scop_family
                          #tag   = tfam.parent.sunid == qfam.parent.sunid ? 1 : -1
                          tag         = sunid_to_supfam_sunid[tsunid] == sunid_to_supfam_sunid[qsunid] ? 1 : -1
                          #cols    = [tag, zscore, tsid, tfam.sccs, tfam.sunid, qfam.sccs, qfam.sunid, len, raws, rvn]
                          cols        = [tag, zscore, qsid, qsccs, qsfam_sunid, tsid, tsccs, tsfam_sunid, len, raws, rvn]

                          file.puts cols.join(", ")
                        end
                      end
                    end
                  end
                  $logger.info "Processing #{fam_dir}: done"
                end
                ActiveRecord::Base.remove_connection
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
          sorted_hits = hits.sort { |a, b| b[1] <=> a[1] }
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


    desc "Generate a ROC table for FUGUE search"
    task :roc_fugue => [:environment] do

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do

        %w[dna rna].each do |na|
          ["std64", "#{na}128", "#{na}256"].each do |env|
            (30..100).step(10) do |weight|

              fm.fork do
                esstdir     = configatron.fuguena_dir.join("essts", na, env)
                famdirs     = esstdir.children.select { |d| d.directory? }
                pred_table  = esstdir.join("rank-#{na}-#{env}-#{weight}.csv")
                fugue_hits  = []

                pred_table.each_line do |line|
                  fugue_hits << line.chomp.split(", ")
                end

                true_pos  = 0
                false_pos = 0
                tf_pairs  = []
                tf_pairs  << [false_pos, true_pos]

                sorted_hits = fugue_hits.sort { |a, b| b[1] <=> a[1] }
                sorted_hits.each do |hit|
                  if hit[0] == "T"
                    true_pos += 1
                  elsif hit[0] == "F"
                    false_pos += 1
                  end
                  tf_pairs << [false_pos, true_pos]
                end

#                roc_table = esstdir + "roc-#{na}-#{env}-#{weight}.csv"
#                roc_table.open('w') { |f| f.puts(tf_pairs.each { |p| p.join(", ") }) }
#
#                [10, 20, 50].each do |cut|
#                  max_tp = 0.0
#                  max_fp = cut.to_f
#
#                  roc_occ_table = esstdir + "roc-#{na}-#{env}-#{weight}-occ#{cut}.csv"
#                  roc_occ_table.open('w') do |file|
#                    tf_pairs.each do |pair|
#                      if pair[0] <= cut
#                        max_tp = pair[1].to_f
#                        file.puts pair.join(", ")
#                      end
#                    end
#                  end
#
#                  roc_frq_table = esstdir + "roc-#{na}-#{env}-#{weight}-frq#{cut}.csv"
#                  roc_frq_table.open('w') do |file|
#                    tf_pairs.each do |pair|
#                      file.puts [pair[0] / max_fp, pair[1] / max_tp].join(", ") if pair[0] <= cut
#                    end
#                  end
#                end

              end # fm.fork

            end
          end
        end
      end
    end

  end
end
