namespace :bipa do
  namespace :generate do

    desc "Generate full set of PDB files for each SCOP family"
    task :fullscop => [:environment] do

      %w[dna rna].each do |na|
        sunids    = ScopFamily.send("reg_#{na}").map(&:sunid).sort
        fulldir  = configatron.family_dir.join("full", na)
        config    = ActiveRecord::Base.remove_connection

        refresh_dir(fulldir) unless configatron.resume

        sunids.forkify(configatron.max_fork) do |sunid|
          ActiveRecord::Base.establish_connection(config)
          family  = ScopFamily.find_by_sunid(sunid)
          famdir = fulldir.join("#{sunid}")

          mkdir_p famdir

          domains = family.leaves.select(&:"reg_#{na}")
          domains.each do |domain|
            if domain.calpha_only?
              $logger.warn "!!! SCOP domain, #{domain.sunid} is C-alpha only structure"
              next
            end

            if domain.has_unks?
              $logger.warn "!!! SCOP domain, #{domain.sunid} has UNKs"
              next
            end

            dom_sid   = domain.sid.gsub(/^g/, "d")
            dom_sunid = domain.sunid
            dom_pdb   = configatron.scop_pdb_dir.join(dom_sid[2..3], "#{dom_sid}.ent")

            if !File.size? dom_pdb
              $logger.error "!!! Cannot find #{dom_pdb}"
              next
            end

            # Generate PDB file only for the first model in NMR structure using Bio::PDB
            File.open(famdir.join("#{domain.sunid}.pdb"), "w") do |f|
              f.puts Bio::PDB.new(IO.read(dom_pdb)).models.first
            end
          end

          $logger.info ">>> Generating full PDB files for #{na.upcase}-binding SCOP family, #{sunid}: done"
          ActiveRecord::Base.remove_connection
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


    desc "Generate representative set of PDB files for each SCOP Family"
    task :repscop => [:environment] do

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do
        %w[dna rna].each do |na|
          sunids  = ScopFamily.send("reg_#{na}").map(&:sunid).sort
          fulldir = configatron.family_dir.join("full", na)
          config  = ActiveRecord::Base.remove_connection

          sunids.each do |sunid|
            fm.fork do
              ActiveRecord::Base.establish_connection(config)

              fam     = ScopFamily.find_by_sunid(sunid)
              repdir  = configatron.family_dir.join("rep", na)
              famdir  = repdir.join(sunid.to_s)

              mkdir_p famdir

              subfams = fam.send("#{na}_binding_subfamilies")
              subfams.each do |subfam|
                domain = subfam.representative

                next if domain.nil?

                dompdb = fulldir.join(sunid.to_s, domain.sunid.to_s + '.pdb')

                if !File.size? dompdb
                  $logger.warn "!!! Cannot find #{dompdb}"
                  next
                end

                # postproces domain pdb file
                # change HETATM MSE into ATOM MET
                # remove HETATM * SE   MSE
                modpdb = famdir.join(dompdb.basename)

                File.open(modpdb, 'w') do |f|
                  IO.foreach(dompdb) do |l|
                    # HETATM 2017 SE   MSE
                    if l[0..5] == "HETATM" and l[12..13] == "SE" and l[17..19] == "MSE"
                      $logger.warn "!!! Omit: #{l.chomp}"
                      next
                    # HETATM 2011  N   MSE
                    # HETATM20783  N   MSE
                    # HETATM  591  N  AMSE
                    elsif l[0..5] == "HETATM" and l[17..19] == "MSE"
                      f.puts l.gsub("HETATM", "ATOM  ").gsub("MSE", "MET").chomp
                    else
                      f.puts l.chomp
                    end
                  end
                end
              end

              $logger.info ">>> Generating representative PDB files for #{na.upcase}-binding SCOP family, #{sunid}: done"
              ActiveRecord::Base.remove_connection
            end
          end
          ActiveRecord::Base.establish_connection(config)
        end
      end
    end


    desc "Generate PDB files for each Subfamily of each SCOP Family"
    task :subscop => [:environment] do

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do
        %w[dna rna].each do |na|
          sunids  = ScopFamily.send("reg_#{na}").map(&:sunid).sort
          subdir  = configatron.family_dir.join("sub", na)
          fulldir = configatron.family_dir.join("full", na)
          config  = ActiveRecord::Base.remove_connection

          sunids.each do |sunid|
            fm.fork do
              ActiveRecord::Base.establish_connection(config)

              fam     = ScopFamily.find_by_sunid(sunid)
              famdir  = subdir.join("#{sunid}")
              subfams = fam.send("#{na}_binding_subfamilies")

              subfams.each do |subfam|
                subfamdir = famdir.join(subfam.id.to_s)

                mkdir_p subfamdir

                subfam.domains.each do |dom|
                  dompdb = fulldir.join(sunid.to_s, dom.sunid.to_s + '.pdb')

                  if !File.exists?(dompdb)
                    $logger.warn "!!! SCOP Domain, #{dom.sunid} might be C-alpha only or having 'UNK' residues"
                    next
                  end

                  # postproces domain pdb file
                  # change HETATM MSE into ATOM MET
                  # remove HETATM * SE   MSE
                  modpdb = subfamdir.join(dompdb.basename)

                  File.open(modpdb, 'w') do |f|
                    IO.foreach(dompdb) do |l|
                      # HETATM 2017 SE   MSE
                      if l[0..5] == "HETATM" and l[12..13] == "SE" and l[17..19] == "MSE"
                        $logger.warn "!!! Omit: #{l.chomp}"
                        next
                      # HETATM 2011  N   MSE
                      # HETATM20783  N   MSE
                      # HETATM  591  N  AMSE
                      elsif l[0..5] == "HETATM" and l[17..19] == "MSE"
                        f.puts l.gsub("HETATM", "ATOM  ").gsub("MSE", "MET").chomp
                      else
                        f.puts l.chomp
                      end
                    end
                  end
                end
              end
              $logger.info ">>> Generating PDB files for subfamilies of each #{na.upcase}-binding SCOP family, #{sunid}: done"
              ActiveRecord::Base.remove_connection
            end
          end
          ActiveRecord::Base.establish_connection(config)
        end
      end
    end


    desc "Generate a figure for each PDB structure"
    task :pdbfig => [:environment] do

      mkdir_p configatron.figure_dir

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


    desc "Generate a figure for each SCOP domain only"
    task :domsolofig => [:environment] do

      mkdir_p configatron.figure_dir

      scop_files = Dir[configatron.family_dir.join("full", "*", "*", "*.pdb").to_s]
      scop_files.each_with_index do |scop_file, i|
        stem    = File.basename(scop_file, ".pdb")
        input   = Rails.root.join("tmp", "#{stem}.molinput")
        fig5    = configatron.figure_dir.join("scop", "#{stem}_5.png") # molscript cannot hangle a long input file name
        fig500  = configatron.figure_dir.join("scop", "#{stem}_only_500.png")
        fig100  = configatron.figure_dir.join("scop", "#{stem}_only_100.png")

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


    desc "Generate a figure for each SCOP domain"
    task :domfig => [:environment] do

      mkdir_p configatron.figure_dir

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
          fig5    = configatron.figure_dir.join("#{stem}_5.png") # molscript cannot hangle a long input file name
          fig500  = configatron.figure_dir.join("#{stem}_500.png")
          fig100  = configatron.figure_dir.join("#{stem}_100.png")

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
    task :usrfile => [:environment] do

      File.open("./tmp/interface_descriptors.txt", "w") do |file|
        DomainInterface.find_each do |int|
          file.puts [int.id, *int.shape_descriptors].join(", ") if int.interface_atoms.size > 3
          $logger.info ">>> Generating USR descriptors for #{int.class}, #{int.id}: done"
        end
      end
    end

  end
end
