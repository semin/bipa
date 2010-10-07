namespace :generate do
  namespace :bipa do

    desc "Generate full set of PDB files for each SCOP family"
    task :all_scop_pdbs => [:environment] do

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do
        %w[dna rna].each do |na|
          sunids  = ScopFamily.send("reg_#{na}").map(&:sunid).sort
          all_dir = configatron.family_dir.join("scop", "all", na)
          conn    = ActiveRecord::Base.remove_connection

          refresh_dir all_dir

          sunids.each_with_index do |sunid, i|
            fm.fork do
              ActiveRecord::Base.establish_connection(conn)
              fam     = ScopFamily.find_by_sunid(sunid)
              fam_dir = all_dir.join + "#{sunid}"

              mkdir_p fam_dir

              doms = fam.leaves.select(&:"reg_#{na}")
              doms.each do |dom|
                if dom.calpha_only?
                  $logger.warn "SCOP domain, #{dom.sid} is C-alpha only structure"
                  next
                end

                if dom.has_unks?
                  $logger.warn "SCOP domain, #{dom.sid} has UNKs"
                  next
                end

                dom_sid   = dom.sid.gsub(/^g/, "d")
                dom_sunid = dom.sunid
                dom_pdb   = configatron.scop_pdb_dir.join(dom_sid[2..3], "#{dom_sid}.ent")

                if !File.size? dom_pdb
                  $logger.error "!!! Cannot find #{dom_pdb}"
                  next
                end

                # Generate PDB file only for the first model in NMR structure using Bio::PDB
                fam_dir.join("#{dom.sunid}.pdb").open("w") do |f|
                  f.puts Bio::PDB.new(IO.read(dom_pdb)).models.first
                end
              end

              $logger.info "Generating all PDB files for #{na.upcase}-binding SCOP family, #{sunid} (#{i+1}/#{sunids.size}): done"
              ActiveRecord::Base.remove_connection
            end
          end
          ActiveRecord::Base.establish_connection(conn)
        end
      end
    end


    desc "Generate representative set of PDB files for each SCOP Family"
    task :rep_scop_pdbs => [:environment] do

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do
        %w[dna rna].each do |na|
          sunids  = ScopFamily.send("reg_#{na}").map(&:sunid).sort
          all_dir = configatron.family_dir.join("scop", "all", na)
          rep_dir = configatron.family_dir.join("scop", "rep", na)
          conn    = ActiveRecord::Base.remove_connection

          refresh_dir rep_dir

          sunids.each_with_index do |sunid, i|
            fm.fork do
              ActiveRecord::Base.establish_connection(conn)
              fam     = ScopFamily.find_by_sunid(sunid)
              fam_dir = rep_dir.join + sunid.to_s

              mkdir_p fam_dir

              sub_fams = fam.send("#{na}_binding_subfamilies")
              sub_fams.each do |sub_fam|
                dom = sub_fam.representative

                if dom.nil?
                  $logger.warn "Skip #{sub_fam.class}, #{sub_fam.id}: cannot find a representative"
                  next
                end

                dom_pdb = all_dir.join(sunid.to_s, dom.sunid.to_s + '.pdb')

                if !dom_pdb.size?
                  $logger.warn "Cannot find #{dom_pdb}"
                  next
                end

                # postproces domain pdb file
                # change HETATM MSE into ATOM MET
                # remove HETATM * SE   MSE
                mod_pdb = fam_dir.join(dom_pdb.basename.to_s)
                mod_pdb.open('w') do |file|
                  IO.foreach(dom_pdb) do |line|
                    # HETATM 2017 SE   MSE
                    if ((line[0..5]   == "HETATM")  &&
                        (line[12..13] == "SE")      &&
                        (line[17..19] == "MSE"))
                      $logger.warn "Skipped #{line.chomp}"
                      next
                    # HETATM 2011  N   MSE
                    # HETATM20783  N   MSE
                    # HETATM  591  N  AMSE
                    elsif ((line[0..5]    == "HETATM") &&
                           (line[17..19]  == "MSE"))
                      file.puts line.gsub("HETATM", "ATOM  ").gsub("MSE", "MET").chomp
                    else
                      file.puts line.chomp
                    end
                  end
                end
              end

              $logger.info "Generating representative PDB files for #{na.upcase}-binding SCOP family, #{sunid} (#{i+1}/#{sunids.size}): done"
              ActiveRecord::Base.remove_connection
            end
          end
          ActiveRecord::Base.establish_connection(conn)
        end
      end
    end


    desc "Generate PDB files for each Subfamily of each SCOP Family"
    task :sub_scop_pdbs => [:environment] do

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do
        %w[dna rna].each do |na|
          sunids  = ScopFamily.send("reg_#{na}").map(&:sunid).sort
          sub_dir = configatron.family_dir.join("scop", "sub", na)
          all_dir = configatron.family_dir.join("scop", "all", na)
          conn    = ActiveRecord::Base.remove_connection

          refresh_dir sub_dir

          sunids.each_with_index do |sunid, i|
            fm.fork do
              ActiveRecord::Base.establish_connection(conn)
              fam       = ScopFamily.find_by_sunid(sunid)
              fam_dir   = sub_dir + sunid.to_s
              sub_fams  = fam.send("#{na}_binding_subfamilies")

              sub_fams.each do |sub_fam|
                sub_fam_dir = fam_dir + sub_fam.id.to_s

                mkdir_p sub_fam_dir

                sub_fam.domains.each do |dom|
                  dom_pdb = all_dir.join(sunid.to_s, dom.sunid.to_s + '.pdb')

                  if !dom_pdb.size?
                    $logger.warn "Skipped SCOP Domain, #{dom.sid}: c-alpha only or having 'UNK' residues"
                    next
                  end

                  # postproces domain pdb file
                  # change HETATM MSE into ATOM MET
                  # remove HETATM * SE   MSE
                  mod_pdb = sub_fam_dir.join(dom_pdb.basename.to_s)
                  mod_pdb.open('w') do |file|
                    IO.foreach(dom_pdb) do |line|
                      # HETATM 2017 SE   MSE
                      if ((line[0..5]   == "HETATM")  &&
                          (line[12..13] == "SE")      &&
                          (line[17..19] == "MSE"))
                        $logger.warn "Skipped #{line.chomp}"
                        next
                        # HETATM 2011  N   MSE
                        # HETATM20783  N   MSE
                        # HETATM  591  N  AMSE
                      elsif ((line[0..5]    == "HETATM") &&
                             (line[17..19]  == "MSE"))
                        file.puts line.gsub("HETATM", "ATOM  ").gsub("MSE", "MET").chomp
                      else
                        file.puts line.chomp
                      end
                    end
                  end
                end
              end
              $logger.info "Generating PDB files for subfamilies of each #{na.upcase}-binding SCOP family, #{sunid} (#{i+1}/#{sunids.size}): done"
              ActiveRecord::Base.remove_connection
            end
          end
          ActiveRecord::Base.establish_connection(conn)
        end
      end
    end


    desc "Generate PDB files for DNA/RNA-binding protein chains"
    task :all_chains_pdb => [:environment] do

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do
        %w[dna rna].each do |na|
          sunids  = ScopFamily.send("reg_#{na}").map(&:sunid).sort
          sub_dir = configatron.family_dir.join("scop", "sub", na)
          all_dir = configatron.family_dir.join("scop", "all", na)
          conn    = ActiveRecord::Base.remove_connection

          refresh_dir sub_dir
        end
      end
    end


    desc "Generate a figure for each PDB structure"
    task :complex_figures => [:environment] do

      mkdir_p configatron.figure_dir.join("pdb")

      pdb_files = Dir[configatron.pdb_dir.join("*.pdb").to_s]
      pdb_files.each_with_index do |pdb_file, i|
        stem    = File.basename(pdb_file, ".pdb")
        input   = Rails.root.join("tmp", "#{stem}.input")
        fig5    = configatron.figure_dir.join("pdb", "#{stem}_5.png") # molscript cannot hangle a long input file name
        fig500  = configatron.figure_dir.join("pdb", "#{stem}_500.png")
        fig100  = configatron.figure_dir.join("pdb", "#{stem}_100.png")

        if File.size?(fig500) && File.size?(fig100)
          $logger.warn "!!! Skipped PDB structure, #{stem}, figures are already created"
          next
        end

        mol_input       = `molauto -notitle -nice #{pdb_file}`.split("\n")
        mol_input[5,0]  = "background grey 1;"

        File.open(input, "w") { |f| f.puts mol_input.join("\n") }
        system "molscript -r < #{input} | render -png #{fig5} -size500x500; rm #{input}; mv #{fig5} #{fig500}"
        system "convert #{fig500} -resize 100x100 #{fig100}"
      end
    end


    desc "Generate a figure for each SCOP domain"
    task :domain_figures => [:environment] do

      mkdir_p configatron.scop_figure_dir

      pdb_files = Dir[configatron.pdb_dir.join("*.pdb").to_s]
      pdb_files.each_with_index do |pdb_file, i|
        pdb_code  = File.basename(pdb_file, ".pdb")
        structure = Structure.find_by_pdb_code(pdb_code.upcase)

        if structure.nil?
          $logger.error "!!! Cannot find #{pdb_code.upcase} in BIPA"
          next
        end

        structure.domains.each do |domain|
          stem    = domain.sunid
          input   = Rails.root.join("tmp", "#{stem}.input")
          fig5    = configatron.scop_figure_dir.join("#{stem}_5.png") # molscript cannot hangle a long input file name
          fig500  = configatron.scop_figure_dir.join("#{stem}_500.png")
          fig100  = configatron.scop_figure_dir.join("#{stem}_100.png")

          if File.size?(fig500) && File.size?(fig100)
            $logger.warn "!!! Skipped SCOP domain, #{domain.sunid}, figures are already created"
            next
          end

          first_res = domain.residues.first
          last_res  = domain.residues.last
          from      = first_res.chain.chain_code + first_res.residue_code.to_s
          to        = last_res.chain.chain_code + last_res.residue_code.to_s

          mol_input       = `molauto -notitle -nice #{pdb_file}`.split("\n")
          mol_input[5,0]  = "  background grey 1;"
          mol_input[10]   = "  set colourparts on, residuecolour amino-acids grey 1;"
          mol_input[11,0] = "  set residuecolour from #{from} to #{to} rainbow;"

          File.open(input, "w") { |f| f.puts mol_input.join("\n") }
          system "molscript -r < #{input} | render -png #{fig5} -size500x500; rm #{input}; mv #{fig5} #{fig500}"
          system "convert #{fig500} -resize 100x100 #{fig100}"
        end
      end
    end


    desc "Generate a figure for each SCOP domain only"
    task :domain_only_figures => [:environment] do

      mkdir_p configatron.scop_figure_dir

      scop_files = Pathname.glob(configatron.family_dir.join("scop", "all", "*", "*", "*.pdb"))
      scop_files.each_with_index do |scop_file, i|
        stem    = File.basename(scop_file, ".pdb")
        input   = Rails.root.join("tmp", "#{stem}.molinput")
        fig5    = configatron.scop_figure_dir.join("#{stem}_only_5.png") # molscript cannot hangle a long input file name
        fig500  = configatron.scop_figure_dir.join("#{stem}_only_500.png")
        fig100  = configatron.scop_figure_dir.join("#{stem}_only_100.png")

        if File.size?(fig500) && File.size?(fig100)
          $logger.warn "!!! Skipped SCOP domain, #{stem}, figures are already created"
          next
        end

        mol_input       = `molauto -notitle -nice #{scop_file}`.split("\n")
        mol_input[5,0]  = "  background grey 1;"

        File.open(input, "w") { |f| f.puts mol_input.join("\n") }
        system "molscript -r < #{input} | render -png #{fig5} -size500x500; rm #{input}; mv #{fig5} #{fig500}"
        system "convert #{fig500} -resize 100x100 #{fig100}"
      end
    end


    desc "Generate a flat file for interfaces table"
    task :interfaces_flat_file => [:environment] do

      File.open("./tmp/interfaces.csv", "w") do |file|
        Interface.find_each do |int|
          begin
            file.puts [
              int.id,
              int.asa,
              int.polarity,
              int.shape_descriptors.to_a,
              int.residue_propensity_vector.to_a,
              int.sse_propensity_vector.to_a
            ].join(",")
          rescue
            next
          end
        end
      end
    end


    desc "Generate a dump file for interface_similarities table"
    task :interface_similarities_dump_file => [:environment] do

      InterfaceStruct = Struct.new(:int_id, :asa, :polarity, :shape_descriptors, :res_composition, :sse_composition)
      interfaces      = []

      IO.foreach("./tmp/interfaces.csv") do |line|
        elements = line.chomp.split(",")
        interfaces << InterfaceStruct.new(elements[0].to_i,
                                          elements[1].to_f,
                                          elements[2].to_f,
                                          NVector[*elements[3..14].map(&:to_f)],
                                          NVector[*elements[15..34].map(&:to_f)],
                                          NVector[*elements[35..42].map(&:to_f)])
      end

      total_count = interfaces.size
      fmanager    = ForkManager.new(configatron.max_fork)

      fmanager.manage do
        File.open("./tmp/interface_similarities.csv", "w") do |file|
          0.upto(total_count -2) do |i|
            (i + 1).upto(total_count - 1) do |j|
              index = j + (total_count * i) - NVector[1..i+1].sum + 1

              fmanager.fork do
                asa_sim = (interfaces[i].asa - interfaces[j].asa).abs.to_similarity_in_c
                pol_sim = (interfaces[i].polarity - interfaces[j].polarity).abs.to_similarity_in_c
                usr_sim = 1.0 / (1 + ((interfaces[i].shape_descriptors - interfaces[j].shape_descriptors).abs.sum / 12.0))
                res_sim = NMath::sqrt((interfaces[i].res_composition - interfaces[j].res_composition)**2).to_similarity_in_c
                sse_sim = NMath::sqrt((interfaces[i].sse_composition - interfaces[j].sse_composition)**2).to_similarity_in_c

                file.puts [
                  index,
                  interfaces[i].int_id,
                  interfaces[j].int_id,
                  asa_sim, pol_sim, usr_sim, res_sim, sse_sim,
                  (asa_sim + pol_sim + usr_sim + res_sim + sse_sim) / 5.0
                ].join(",")
                #$logger.info ">>> Updating interface distances between interface #{interfaces[i].id} and #{interfaces[j].id}: done (#{index}/#{total})"
              end
            end
          end
        end
      end # fmanager.manage
    end


    desc "Generate a dump file for interface atom coordiantes"
    task :domain_interface_usr_descriptors => [:environment] do

      klass = DomainNucleicAcidInterface
      File.open("./tmp/#{klass.to_s.downcase}_descriptors.txt", "w") do |file|
        klass.find_each do |i|
          na = i.interface_to.downcase
          if i.send("#{na}_binding_atoms").size > 3
            file.puts [i.id, *i.shape_descriptors].join(", ")
            $logger.info "Generating USR descriptors for #{i.class}, #{i.id}: done"
          else
            $logger.info "Skip, #{i.class}, #{i.id}: < 3 #{na.upcase} binding atoms"
          end
        end
      end
    end


    desc "Generate a dump file for interface atom coordiantes"
    task :chain_interface_usr_descriptors => [:environment] do

      klass = ChainNucleicAcidInterface
      File.open("./tmp/#{klass.to_s.downcase}_descriptors.txt", "w") do |file|
        klass.find_each do |i|
          na = i.interface_to.downcase
          if i.send("#{na}_binding_atoms").size > 3
            file.puts [i.id, *i.shape_descriptors].join(", ")
            $logger.info "Generating USR descriptors for #{i.class}, #{i.id}: done"
          else
            $logger.info "Skip, #{i.class}, #{i.id}: < 3 #{na.upcase} binding atoms"
          end
        end
      end
    end
  end


  namespace :fuguena do

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


  namespace :nabal do

    desc "Generate non-redundant protein-DNA/RNA chain sets for Nabal training"
    task :nrchains => [:environment] do

      #refresh_dir configatron.nabal_dir

      fm = ForkManager.new(2)
      fm.manage do
        config = ActiveRecord::Base.remove_connection

        %w[dna rna].each do |na|
          fm.fork do
            ActiveRecord::Base.establish_connection(config)

            cnt = 0
            fasta = configatron.nabal_dir + "#{na}_set.fasta"
            fasta.open('w') do |file|
              klass = "Chain#{na.capitalize}Interface".constantize
              klass.find_each do |chain_interface|
                chain     = chain_interface.chain
                structure = chain.model.structure
                if structure.resolution && (structure.resolution < 3.0)
                  aaseq = chain.res_seq
                  if ((aaseq !~ /X/i) &&
                      (aaseq.size > 30) &&
                      ((chain.send("#{na}_binding_residues").size > 5)))
                    entry_id  = "#{structure.pdb_code}_#{chain.chain_code}"
                    file.puts ">#{entry_id}"
                    file.puts aaseq
                    $logger.debug "#{entry_id} is selected as a #{na.upcase} binding chain (#{cnt+=1})."
                  end
                end
              end
            end

            # Run blastclust to make non-redundant protein-DNA/RNA chain sets
            cwd = pwd
            chdir configatron.nabal_dir
            sh "blastclust -i #{na}_set.fasta -o #{na}_set.cluster25 -L .9 -b F -p T -S 25"
            chdir cwd
            $logger.info "Running blastclust for non-redundant protein-#{na.upcase} chain sets: done"

            ActiveRecord::Base.remove_connection
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


    desc "Generate lists of non-redundant protein-DNA/RNA chain sets"
    task :nrchainlists => [:environment] do

      %w[dna rna].each do |na|
        na_set    = configatron.nabal_dir + "#{na}_set.cluster25"
        list_file = configatron.nabal_dir + (na_set.basename(".cluster25").to_s + ".list")
        list_file.open("w") do |list|
          na_set.each_line do |line|
            unless line.empty?
              rep         = line.chomp.split(/\s+/).sort { |x, y|
                x.split("_").last.to_i <=> y.split("_").last.to_i
              }.last
              pdb_code    = rep.split("_")[0]
              chain_code  = rep.split("_")[1]
              list.puts "#{pdb_code}_#{chain_code}"
            end
          end
        end
      end
    end


    desc "Generate PSSMs for each of non-redundant protein-DNA/RNA chain sets"
    task :pssms => [:environment] do

      #blast_db = Rails.root.join("tmp", "nr100_24Jun09.clean.fasta")
      blast_db  = configatron.nabal_dir + "uniref100_20100826.fasta"
      #fm        = ForkManager.new(configatron.max_fork)
      fm        = ForkManager.new(8)
      fm.manage do
        config = ActiveRecord::Base.remove_connection

        %w[dna rna].each do |na|
          nalist = configatron.nabal_dir + "#{na}_set.list"
          nalist.each_line do |line|
            fm.fork do
              ActiveRecord::Base.establish_connection(config)

              stem        = line.chomp
              pdb_code    = stem.split("_").first
              chain_code  = stem.split("_").last
              structure   = Structure.find_by_pdb_code(pdb_code.upcase)
              chain       = structure.models[0].chains.find_by_chain_code(chain_code)

              # create input fasta file
              (configatron.nabal_dir + "blast/#{stem}.fasta").open("w") do |fa|
                fa.puts ">#{stem}"
                #fa.puts aa_residues.map(&:one_letter_code).join('')
                fa.puts chain.res_seq
              end

              # run PSI-Blast against UniRef100 and generate PSSMs
              # be aware that there are overlapping chains bindng DNA/RNA at the same time!
              cwd = pwd
              chdir configatron.nabal_dir
              #system "blastpgp -i #{stem}.fasta -d #{blast_db} -e 1e-2 -h 1e-2 -j 5 -m 7 -o #{stem}.blast.xml -a 1 -C #{stem}.asnt -Q #{stem}.pssm -u 1 -J T -W 2"
              system "blastpgp -i ./blast/#{stem}.fasta -d #{blast_db} -j 3 -m 7 -o ./blast/#{stem}.blast.xml -C ./blast/#{stem}.asnt -Q ./blast/#{stem}.pssm -u 1 -J T -W 2"
              chdir cwd

              $logger.info "PSI-BLAST search for #{stem}.pdb from #{na.upcase} set: done"
              ActiveRecord::Base.remove_connection
            end
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


    desc "Generate input feature statistics for Nabal"
    task :input_stats => [:environment] do

      %w[dna rna].each do |na|
        nastem      = "#{na}_set"
        nalist      = configatron.nabal_dir + "#{nastem}.list"
        nabal_stat  = configatron.nabal_dir + "nabal-#{na}-stat.csv"
        nrchains    = IO.readlines(nalist).map(&:chomp)
        interfaces  = []
        surfaces    = []
        cores       = []

        nabal_stat.open('w') do |file|
          nrchains.each_with_index do |nrchain, i|
            #$logger.info "Processing #{nrchain} of #{na.upcase} set (#{i+1}/#{nrchains.size})"

            pdb_code      = nrchain.split("_").first
            chain_code    = nrchain.split("_").last
            structure     = Structure.find_by_pdb_code(pdb_code.upcase)
            chain         = structure.models[0].chains.find_by_chain_code(chain_code)
            aa_residues   = chain.aa_residues
            nab_residues  = chain.send("#{na}_binding_residues")
            nanb_residues = aa_residues - nab_residues

            #$logger.info [
            file.puts [
              na.upcase,
              pdb_code,
              chain_code,
              structure.resolution,
              chain.molecule,
              nab_residues.size,
              nanb_residues.size
            ].join("\t")

            #kdtree        = Bipa::KDTree.new

            #aa_residues.each { |r| r.atoms.each { |c| kdtree.insert(c) } }
            #aa_residues.each do |residue|
              ## USR descriptors
              #ca = residue.atoms.find_by_atom_name('CA')

              #if ca.nil?
                #$logger.warn "Skip #{pdb_code}/#{chain_code}/#{i}/#{residue.residue_name}, no CA!"
                #next
              #end

              #ncas          = kdtree.neighbors(ca, 12).map(&:point)
              #usr_features  = AtomSet.new(ncas).shape_descriptors.to_a

              #if residue.on_interface?
                #interfaces << usr_features
              #elsif residue.on_surface?
                #surfaces << usr_features
              #else
            #cores << usr_features
            #end
            #end
          end
        end

        #File.open("#{nastem}-usr-interfaces.csv", 'w') do |f|
        #interfaces.each { |i| f.puts i.join(", ") }
        #end
        #File.open("#{nastem}-usr-surfaces.csv", 'w') do |f|
        #surfaces.each { |i| f.puts i.join(", ") }
        #end
        #File.open("#{nastem}-usr-cores.csv", 'w') do |f|
        #cores.each { |i| f.puts i.join(", ") }
        #end
      end
    end


    desc "Generate vectorized input features for Nabal traning & testing"
    task :input_features => [:environment] do

      require "facets"

      winsize = 9
      radius  = winsize / 2

      fm = ForkManager.new(2)
      fm.manage do
        config = ActiveRecord::Base.remove_connection

        %w[dna rna].each do |na|
          fm.fork do
            ActiveRecord::Base.establish_connection(config)

            esst64      = configatron.nabal_dir + "ulla-#{na}64-pid90-sigma0.0001-out2.mat"
            esst64_obj  = Bipa::Essts.new(esst64)
            esst128     = configatron.nabal_dir + "ulla-#{na}128-pid90-sigma0.0001-out2.mat"
            esst128_obj = Bipa::Essts.new(esst128)

            nastem      = "#{na}_set"
            nalist      = configatron.nabal_dir + "#{nastem}.list"
            nrchains    = IO.readlines(nalist).map(&:chomp)
            seed        = srand(21)
            clusters    = nrchains.shuffle.chunk(5)

            clusters.each_with_index do |cluster, ci|
              test_set  = cluster
              train_set = (clusters - cluster).flatten

              [test_set, train_set].each_with_index do |set, si|
                set_name            = si == 0 ? 'test' : 'train'

                svm_ipf_aa              = configatron.nabal_dir.join("svm-#{na}-#{ci+1}-aa.#{set_name}").open('w')
                svm_ipf_aa_pssm         = configatron.nabal_dir.join("svm-#{na}-#{ci+1}-aa-pssm.#{set_name}").open('w')
                svm_ipf_aa_pssm_dist64  = configatron.nabal_dir.join("svm-#{na}-#{ci+1}-aa-pssm-dist64.#{set_name}").open('w')
                svm_ipf_aa_pssm_dist128 = configatron.nabal_dir.join("svm-#{na}-#{ci+1}-aa-pssm-dist128.#{set_name}").open('w')

                #rnd_ipf_aa              = configatron.nabal_dir.join("rnd-#{na}-#{ci+1}-aa.#{set_name}").open('w')
                #rnd_ipf_aa_pssm         = configatron.nabal_dir.join("rnd-#{na}-#{ci+1}-aa-pssm.#{set_name}").open('w')
                #rnd_ipf_aa_pssm_dist64  = configatron.nabal_dir.join("rnd-#{na}-#{ci+1}-aa-pssm-dist64.#{set_name}").open('w')
                #rnd_ipf_aa_pssm_dist128 = configatron.nabal_dir.join("rnd-#{na}-#{ci+1}-aa-pssm-dist128.#{set_name}").open('w')

                set.each do |nrchain|
                  pdb_code        = nrchain.split("_").first
                  chain_code      = nrchain.split("_").last
                  structure       = Structure.find_by_pdb_code(pdb_code.upcase)
                  chain           = structure.models[0].chains.find_by_chain_code(chain_code)
                  aa_residues     = chain.sorted_aa_residues
                  nab_residues    = chain.send("#{na}_binding_residues")
                  nanb_residues   = aa_residues - nab_residues
                  #kdtree          = Bipa::KDTree.new
                  #aa_residues.each { |r| r.atoms.each { |c| kdtree.insert(c) } }

                  # balance NA-binding and NA-non-binding residue numbers
                  if nanb_residues.size > nab_residues.size
                    snanb_residues  = []
                    nab_residues.size.times do
                      res = nanb_residues[rand(nanb_residues.size)]
                      snanb_residues << res
                      nanb_residues.delete(res)
                    end
                    nanb_residues = snanb_residues
                  end

                  # read PSSM file
                  pssm_ress = []
                  pssm_vecs = []
                  pssm_file = configatron.nabal_dir + "blast/#{nrchain}.pssm"
                  $logger.error "!!! #{pssm_file} does not exits" unless File.exists? pssm_file

                  IO.foreach(pssm_file) do |line|
                    line.chomp!.strip!
                    if line =~ /^\d+\s+\w+/
                      columns   = line.split(/\s+/)
                      pssm_ress << columns[1]
                      pssm_vecs << NVector[*columns[2..21].map { |c| Float(c) }]
                    end
                  end

                  ## create libSVM train file
                  sel_residues = nab_residues + nanb_residues
                  sel_residues.each do |residue|
                    # index
                    ai = aa_residues.index(residue)

                    # binding activily label
                    label = residue.send("binding_#{na}?") ? '1' : '-1'

                    # 1-Dimensional features
                    seq_features = (-radius..radius).map { |distance|
                      if (ai + distance) >= 0 && aa_residues[ai + distance]
                        aa_residues[ai + distance].array20
                      else
                        AaResidue::ZeroArray20
                      end
                    }.flatten

                    # PSSM features
                    res_one = residue.one_letter_code
                    if res_one != pssm_ress[ai]
                      $logger.error "#{nrchain}'s #{ai+1}th residue: #{res_one} != #{pssm_ress[ai]}"
                      exit 1
                    end

                    pssm_features = (-radius..radius).map { |distance|
                      if (ai + distance) >= 0 && pssm_vecs[ai + distance]
                        pssm_vecs[ai + distance].to_a
                      else
                        AaResidue::ZeroArray20
                      end
                    }.flatten

                    # Ditance between PSSMs and ESST columns
                    dist64_features = esst64_obj.essts.map { |esst|
                      esst_col  = NVector[*esst.scores_from(res_one).transpose.to_a[0]]
                      NMath::sqrt((esst_col - pssm_vecs[ai])**2)
                    }.flatten

                    dist128_features  = esst128_obj.essts.map { |esst|
                      esst_col  = NVector[*esst.scores_from(res_one).transpose.to_a[0]]
                      NMath::sqrt((esst_col - pssm_vecs[ai])**2)
                    }.flatten

                    # create input feature files for traning and testing
                    svm_ipf_aa.puts               [label, seq_features.map_with_index { |f, i| "#{i+1}:#{f}" }.join(' ')].join(' ')
                    svm_ipf_aa_pssm.puts          [label, (seq_features + pssm_features).map_with_index { |f, i| "#{i+1}:#{f}" }.join(' ') ].join(' ')
                    svm_ipf_aa_pssm_dist64.puts   [label, (seq_features + pssm_features + dist64_features).map_with_index { |f, i| "#{i+1}:#{f}" }.join(' ')].join(' ')
                    svm_ipf_aa_pssm_dist128.puts  [label, (seq_features + pssm_features + dist128_features).map_with_index { |f, i| "#{i+1}:#{f}" }.join(' ')].join(' ')

                    #rnd_ipf_aa.puts               [label, *seq_features].join(',')
                    #rnd_ipf_aa_pssm.puts          [label, *seq_features, *pssm_features].join(',')
                    #rnd_ipf_aa_pssm_dist64.puts   [label, *seq_features, *pssm_features, *dist64_features].join(',')
                    #rnd_ipf_aa_pssm_dist128.puts  [label, *seq_features, *pssm_features, *dist128_features].join(',')

                    #pssm_norm_features = pssm_features.map { |p| 1 / (1 + 1.0 / Math::E**-p) }

                    ## 3-dimensional features from here!!!

                    ## SSE
                    #sse_features = if residue.helix?
                    #[1, 0, 0]
                    #elsif residue.beta_sheet?
                    #[0, 1, 0]
                    #else
                    #[0, 0, 1]
                    #end

                    ## ASA
                    #asa_feature = [residue.relative_unbound_asa]

                    ## Spatial neighbors

                    ## USR descriptors
                    #ca = residue.atoms.find_by_atom_name('CA')

                    #if ca.nil?
                    #$logger.warn "Skip #{pdb_code}/#{chain_code}/#{i}/#{residue.residue_name}, no CA!"
                    #next
                    #end

                    #ncas          = kdtree.neighbors(ca, 12).map(&:point)
                    #usr_features  = AtomSet.new(ncas).shape_descriptors.to_a

                    ## Concatenate all the input features into total_features
                    #total_features = seq_features + pssm_features + sse_features + asa_feature + usr_features

                    ## Create libSVM input feature file
                    #feature.puts label + " " + total_features.map_with_index { |f, i| "#{i + 1}:#{f}" }.join(' ')
                  end
                end

                svm_ipf_aa.close
                svm_ipf_aa_pssm.close
                svm_ipf_aa_pssm_dist64.close
                svm_ipf_aa_pssm_dist128.close

              end
            end
            ActiveRecord::Base.remove_connection
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


    desc "Generate performance measurements for NABAL"
    task :perf9 => [:environment] do
      fm = ForkManager.new(5)
      fm.manage do
        cwd     = pwd
        win     = 9
        nos     = (1..5).to_a
        nas     = %w[dna rna]
        nas.each do |na|
          nos.each do |no|
            fm.fork do
              win_dir = configatron.nabal_dir + "win#{win}"
              chdir win_dir

              stem_aa               = "svm-#{na}-#{no}-aa"
              stem_aa_pssm          = "svm-#{na}-#{no}-aa-pssm"
              stem_aa_pssm_dist64   = "svm-#{na}-#{no}-aa-pssm-dist64"
              stem_aa_pssm_dist128  = "svm-#{na}-#{no}-aa-pssm-dist128"

              system("svm-predict -b 1 #{stem_aa}.test.scale              #{stem_aa}.train.scale.model              #{stem_aa}.predict              > #{stem_aa}.perf")
              system("svm-predict -b 1 #{stem_aa_pssm}.test.scale         #{stem_aa_pssm}.train.scale.model         #{stem_aa_pssm}.predict         > #{stem_aa_pssm}.perf")
              system("svm-predict -b 1 #{stem_aa_pssm_dist64}.test.scale  #{stem_aa_pssm_dist64}.train.scale.model  #{stem_aa_pssm_dist64}.predict  > #{stem_aa_pssm_dist64}.perf")
              system("svm-predict -b 1 #{stem_aa_pssm_dist128}.test.scale #{stem_aa_pssm_dist128}.train.scale.model #{stem_aa_pssm_dist128}.predict > #{stem_aa_pssm_dist128}.perf")

              chdir cwd
            end
          end
        end
      end
    end


    desc "Generate SVM models and predictions for NABAL"
    task :rbfpred9 => [:environment] do

      fm = ForkManager.new(5)
      fm.manage do
        cwd     = pwd
        svm_dir = Pathname.new("~/BiO/Install/libsvm/tools").expand_path
        grid_py = svm_dir + "grid.py"
        win     = 9
        nos     = (1..5).to_a
        #nas     = %w[dna rna]
        nas     = %w[rna]
        nas.each do |na|
          nos.each do |no|
            fm.fork do
              win_dir = configatron.nabal_dir + "win#{win}"
              chdir win_dir

              stem_aa               = "svm-#{na}-#{no}-aa"
              stem_aa_pssm          = "svm-#{na}-#{no}-aa-pssm"
              stem_aa_pssm_dist64   = "svm-#{na}-#{no}-aa-pssm-dist64"
              stem_aa_pssm_dist128  = "svm-#{na}-#{no}-aa-pssm-dist128"

              #system("svm-scale -l -1 -u 1 -s #{stem_aa}.range #{stem_aa}.train > #{stem_aa}.train.scale")
              #system("svm-scale -l -1 -u 1 -s #{stem_aa_pssm}.range #{stem_aa_pssm}.train > #{stem_aa_pssm}.train.scale")
              #system("svm-scale -l -1 -u 1 -s #{stem_aa_pssm_dist64}.range #{stem_aa_pssm_dist64}.train > #{stem_aa_pssm_dist64}.train.scale")
              #system("svm-scale -l -1 -u 1 -s #{stem_aa_pssm_dist128}.range #{stem_aa_pssm_dist128}.train > #{stem_aa_pssm_dist128}.train.scale")

              #system("svm-scale -r #{stem_aa}.range #{stem_aa}.test > #{stem_aa}.test.scale")
              #system("svm-scale -r #{stem_aa_pssm}.range #{stem_aa_pssm}.test > #{stem_aa_pssm}.test.scale")
              #system("svm-scale -r #{stem_aa_pssm_dist64}.range #{stem_aa_pssm_dist64}.test > #{stem_aa_pssm_dist64}.test.scale")
              #system("svm-scale -r #{stem_aa_pssm_dist128}.range #{stem_aa_pssm_dist128}.test > #{stem_aa_pssm_dist128}.test.scale")

              #system("subset.py #{stem_aa}.train.scale 500 > #{stem_aa}.train.scale.sub500")
              #system("subset.py #{stem_aa_pssm}.train.scale 500 > #{stem_aa_pssm}.train.scale.sub500")
              system("subset.py #{stem_aa_pssm_dist64}.train.scale 5000 > #{stem_aa_pssm_dist64}.train.scale.sub5000")
              system("subset.py #{stem_aa_pssm_dist128}.train.scale 5000 > #{stem_aa_pssm_dist128}.train.scale.sub5000")

              #out_grid_aa               = `grid.py #{stem_aa}.train.scale.sub500`.split("\n")[-1].split
              #out_grid_aa_pssm          = `grid.py #{stem_aa_pssm}.train.scale.sub500`.split("\n")[-1].split
              out_grid_aa_pssm_dist64   = `grid.py #{stem_aa_pssm_dist64}.train.scale.sub5000`.split("\n")[-1].split
              out_grid_aa_pssm_dist128  = `grid.py #{stem_aa_pssm_dist128}.train.scale.sub5000`.split("\n")[-1].split

              #system("svm-train -b 1 -c #{out_grid_aa[0]} -g #{out_grid_aa[1]} #{stem_aa}.train.scale")
              #system("svm-train -b 1 -c #{out_grid_aa_pssm[0]} -g #{out_grid_aa_pssm[1]} #{stem_aa_pssm}.train.scale")
              system("svm-train -b 1 -c #{out_grid_aa_pssm_dist64[0]} -g #{out_grid_aa_pssm_dist64[1]} #{stem_aa_pssm_dist64}.train.scale")
              system("svm-train -b 1 -c #{out_grid_aa_pssm_dist128[0]} -g #{out_grid_aa_pssm_dist128[1]} #{stem_aa_pssm_dist128}.train.scale")

              #system("svm-predict -b 1 #{stem_aa}.test.scale              #{stem_aa}.train.scale.model              #{stem_aa}.predict              > #{stem_aa}.perf")
              #system("svm-predict -b 1 #{stem_aa_pssm}.test.scale         #{stem_aa_pssm}.train.scale.model         #{stem_aa_pssm}.predict         > #{stem_aa_pssm}.perf")
              system("svm-predict -b 1 #{stem_aa_pssm_dist64}.test.scale  #{stem_aa_pssm_dist64}.train.scale.model  #{stem_aa_pssm_dist64}.predict  > #{stem_aa_pssm_dist64}.perf")
              system("svm-predict -b 1 #{stem_aa_pssm_dist128}.test.scale #{stem_aa_pssm_dist128}.train.scale.model #{stem_aa_pssm_dist128}.predict > #{stem_aa_pssm_dist128}.perf")

              chdir cwd
            end
          end
        end
      end
    end


    desc "Generate SVM models and predictions for NABAL"
    task :linpred7 => [:environment] do

      fm = ForkManager.new(5)
      fm.manage do
        cwd     = pwd
        svm_dir = Pathname.new("~/BiO/Install/libsvm/tools").expand_path
        grid_py = svm_dir + "grid-lin.py"
        win     = 7
        nos     = (1..5).to_a
        nas     = %w[dna rna]
        nas.each do |na|
          nos.each do |no|
            fm.fork do
              win_dir = configatron.nabal_dir + "win#{win}"
              chdir win_dir

              system(stem_aa               = "svm-#{na}-#{no}-aa")
              system(stem_aa_pssm          = "svm-#{na}-#{no}-aa-pssm")
              system(stem_aa_pssm_dist64   = "svm-#{na}-#{no}-aa-pssm-dist64")
              system(stem_aa_pssm_dist128  = "svm-#{na}-#{no}-aa-pssm-dist128")

              system(cmd_scale1_aa               = "svm-scale -l -1 -u 1 -s #{stem_aa}.range #{stem_aa}.train > #{stem_aa}.train.scale")
              system(cmd_scale1_aa_pssm          = "svm-scale -l -1 -u 1 -s #{stem_aa_pssm}.range #{stem_aa_pssm}.train > #{stem_aa_pssm}.train.scale")
              system(cmd_scale1_aa_pssm_dist64   = "svm-scale -l -1 -u 1 -s #{stem_aa_pssm_dist64}.range #{stem_aa_pssm_dist64}.train > #{stem_aa_pssm_dist64}.train.scale")
              system(cmd_scale1_aa_pssm_dist128  = "svm-scale -l -1 -u 1 -s #{stem_aa_pssm_dist128}.range #{stem_aa_pssm_dist128}.train > #{stem_aa_pssm_dist128}.train.scale")

              system(cmd_scale2_aa               = "svm-scale -r #{stem_aa}.range #{stem_aa}.test > #{stem_aa}.test.scale")
              system(cmd_scale2_aa_pssm          = "svm-scale -r #{stem_aa_pssm}.range #{stem_aa_pssm}.test > #{stem_aa_pssm}.test.scale")
              system(cmd_scale2_aa_pssm_dist64   = "svm-scale -r #{stem_aa_pssm_dist64}.range #{stem_aa_pssm_dist64}.test > #{stem_aa_pssm_dist64}.test.scale")
              system(cmd_scale2_aa_pssm_dist128  = "svm-scale -r #{stem_aa_pssm_dist128}.range #{stem_aa_pssm_dist128}.test > #{stem_aa_pssm_dist128}.test.scale")

              #system(cmd_subset_aa               = "subset.py #{stem_aa}.train.scale 100 > #{stem_aa}.train.scale.sub100")
              #system(cmd_subset_aa_pssm          = "subset.py #{stem_aa_pssm}.train.scale 100 > #{stem_aa_pssm}.train.scale.sub100")
              #system(cmd_subset_aa_pssm_dist64   = "subset.py #{stem_aa_pssm_dist64}.train.scale 100 > #{stem_aa_pssm_dist64}.train.scale.sub100")
              #system(cmd_subset_aa_pssm_dist128  = "subset.py #{stem_aa_pssm_dist128}.train.scale 100 > #{stem_aa_pssm_dist128}.train.scale.sub100")

              out_grid_aa               = `grid-lin.py -log2g 1,1,1 -svmtrain ~/BiO/Install/liblinear/train -s 2 #{stem_aa}.train.scale`.split("\n")[-1].split
              out_grid_aa_pssm          = `grid-lin.py -log2g 1,1,1 -svmtrain ~/BiO/Install/liblinear/train -s 2 #{stem_aa_pssm}.train.scale`.split("\n")[-1].split
              out_grid_aa_pssm_dist64   = `grid-lin.py -log2g 1,1,1 -svmtrain ~/BiO/Install/liblinear/train -s 2 #{stem_aa_pssm_dist64}.train.scale`.split("\n")[-1].split
              out_grid_aa_pssm_dist128  = `grid-lin.py -log2g 1,1,1 -svmtrain ~/BiO/Install/liblinear/train -s 2 #{stem_aa_pssm_dist128}.train.scale`.split("\n")[-1].split

              system(cmd_train_aa              = "train -s 2 -c #{out_grid_aa[0]} #{stem_aa}.train.scale")
              system(cmd_train_aa_pssm         = "train -s 2 -c #{out_grid_aa_pssm[0]} #{stem_aa_pssm}.train.scale")
              system(cmd_train_aa_pssm_dist64  = "train -s 2 -c #{out_grid_aa_pssm_dist64[0]} #{stem_aa_pssm_dist64}.train.scale")
              system(cmd_train_aa_pssm_dist128 = "train -s 2 -c #{out_grid_aa_pssm_dist128[0]} #{stem_aa_pssm_dist128}.train.scale")

              system(cmd_predict_aa              = "predict -b 1 #{stem_aa}.test.scale #{stem_aa}.train.scale.model #{stem_aa}.predict")
              system(cmd_predict_aa_pssm         = "predict -b 1 #{stem_aa_pssm}.test.scale #{stem_aa_pssm}.train.scale.model #{stem_aa_pssm}.predict")
              system(cmd_predict_aa_pssm_dist64  = "predict -b 1 #{stem_aa_pssm_dist64}.test.scale #{stem_aa_pssm_dist64}.train.scale.model #{stem_aa_pssm_dist64}.predict")
              system(cmd_predict_aa_pssm_dist128 = "predict -b 1 #{stem_aa_pssm_dist128}.test.scale #{stem_aa_pssm_dist128}.train.scale.model #{stem_aa_pssm_dist128}.predict")

              chdir cwd
            end
          end
        end
      end
    end

  end
end
