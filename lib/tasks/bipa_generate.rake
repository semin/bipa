namespace :bipa do
  namespace :generate do

    desc "Generate full set of PDB files for each SCOP family"
    task :full_scop_pdbs => [:environment] do

      %w[dna rna].each do |na|
        sunids    = ScopFamily.send("reg_#{na}").map(&:sunid).sort
        full_dir  = configatron.family_dir.join("full", na)
        fmanager  = ForkManager.new(configatron.max_fork)

        refresh_dir(full_dir) unless configatron.resume

        fmanager.manage do
          config = ActiveRecord::Base.remove_connection

          sunids.each_with_index do |sunid, i|
            fmanager.fork do
              ActiveRecord::Base.establish_connection(config)

              family  = ScopFamily.find_by_sunid(sunid)
              fam_dir = full_dir.join("#{sunid}")

              mkdir_p fam_dir

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
                  $logger.warn "!!! Cannot find #{dom_pdb}"
                  exit 1
                end

                # Generate PDB file only for the first model in NMR structure using Bio::PDB
                File.open(fam_dir.join("#{domain.sunid}.pdb"), "w") do |f|
                  f.puts Bio::PDB.new(IO.read(dom_pdb)).models.first
                end
              end

              ActiveRecord::Base.remove_connection
              $logger.info ">>> Generating full set of PDB files for #{na.upcase}-binding SCOP family, #{sunid}: done (#{i + 1}/#{sunids.size})"
            end
          end
          ActiveRecord::Base.establish_connection(config)
        end
      end
    end


    desc "Generate representative set of PDB files for each SCOP Family"
    task :rep_scop_pdbs => [:environment] do

      %w[dna rna].each do |na|
        sunids    = ScopFamily.send("reg_#{na}").map(&:sunid).sort
        full_dir  = configatron.family_dir.join("full", na)
        fmanager  = ForkManager.new(configatron.max_fork)

        fmanager.manage do
          config = ActiveRecord::Base.remove_connection

          sunids.each_with_index do |sunid, i|
            fmanager.fork do
              ActiveRecord::Base.establish_connection(config)

              family = ScopFamily.find_by_sunid(sunid)

              configatron.rep_pids.each do |pid|
                rep_dir = configatron.family_dir.join("rep#{pid}", na)
                fam_dir = rep_dir.join(sunid.to_s)
                mkdir_p fam_dir

                subfamilies = family.send("red#{pid}_#{na}_binding_subfamilies")
                subfamilies.each do |subfamily|
                  domain = subfamily.representative
                  next if domain.nil?

                  domain_pdb_file = full_dir.join(sunid.to_s, domain.sunid.to_s + '.pdb')

                  if !File.size? domain_pdb_file
                    $logger.warn "!!! Cannot find #{domain_pdb_file}"
                    exit 1
                  end

                  cp domain_pdb_file, fam_dir
                end
              end
              ActiveRecord::Base.remove_connection
            end
            $logger.info ">>> Generating representative PDB files for #{na.upcase}-binding SCOP family, #{sunid}: done (#{i + 1}/#{sunids.size})"
            ActiveRecord::Base.establish_connection(config)
          end
        end
      end
    end


    desc "Generate PDB files for each Subfamily of each SCOP Family"
    task :sub_scop_pdbs => [:environment] do

      %w[dna rna].each do |na|
        sunids    = ScopFamily.send("reg_#{na}").map(&:sunid).sort
        sub_dir   = configatron.family_dir.join("sub", na)
        full_dir  = configatron.family_dir.join("full", na)
        fmanager  = ForkManager.new(configatron.max_fork)

        refresh_dir(sub_dir) unless configatron.resume

        fmanager.manage do
          config = ActiveRecord::Base.remove_connection

          sunids.each_with_index do |sunid, i|
            fmanager.fork do
              ActiveRecord::Base.establish_connection(config)

              family  = ScopFamily.find_by_sunid(sunid)
              fam_dir = sub_dir.join("#{sunid}")

              configatron.rep_pids.each do |pid|
                subfamilies = family.send("red#{pid}_#{na}_binding_subfamilies")
                subfamilies.each do |subfamily|
                  subfam_dir = fam_dir.join("red#{pid}", subfamily.id.to_s)
                  mkdir_p subfam_dir

                  domains = subfamily.domains
                  domains.each do |domain|
                    domain_pdb_file = full_dir.join(sunid.to_s, domain.sunid.to_s + '.pdb')

                    if !File.exists?(domain_pdb_file)
                      $logger.warn "!!! SCOP Domain, #{domain.sunid} might be C-alpha only or having 'UNK' residues"
                      next
                    end
                    cp domain_pdb_file, subfam_dir
                  end # domains.each
                end # subfamilies.each
              end # configatron.rep_pids

              $logger.info ">>> Generating PDB files for #{na.upcase}-binding subfamilies of each SCOP Family, #{sunid}: done (#{i + 1}/#{sunids.size})"
              ActiveRecord::Base.remove_connection
            end
          end
          ActiveRecord::Base.establish_connection(config)
        end
      end
    end


    desc "Generate DNA/RNA TEM file for each alignments"
    task :tem_files => [:environment] do

      %w[dna rna].each do |na|
        configatron.rep_pids.each do |si|

          rep_dir = configatron.alignment_dir.join("rep#{si}")

          Dir.new(rep_dir).each do |dir|
            next if dir =~ /^\./

            family    = Scop.find_by_sunid(dir)
            alignment = family.send(:"rep#{si}_alignment")

            next unless alignment

            fam_dir   = File.join(rep_dir, dir)
            tem_file  = File.join(fam_dir, "baton.tem")

            next unless File.size? tem_file

            new_tem_file = File.join(fam_dir, "baton_na.tem")
  #          cp tem_file, new_tem_file

            File.open(new_tem_file, "w") do |file|

              $logger.info "Working on SCOP family, #{dir} ..."

              alignment.sequences.each do |sequence|
                sunid = sequence.domain.sunid

                $logger.info "Adding DNA/RNA interface environment for #{sunid} ..."

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

                sequence.positions.each_with_index do |position, pi|
                  if pi != 0 and pi % 75 == 0
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

                  if position.gap?
                    res_tem << "-"
                    sec_tem << "-"
                    acc_tem << "-"

                    dna_tem << "-"
                    rna_tem << "-"

                    hbond_dna_tem   << "-"
                    whbond_dna_tem  << "-"
                    vdw_dna_tem     << "-"

                    hbond_rna_tem   << "-"
                    whbond_rna_tem  << "-"
                    vdw_rna_tem     << "-"

                    next
                  end

                  res = position.residue

                  res_tem << position.residue_name
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
            end
          end
        end
      end
    end


    desc "Generate ESSTs for each representative set of SCOP families"
    task :essts => [:environment] do

      #refresh_dir(configatron.esst_dir) unless configatron.resume

      %w[dna rna].each do |na|
        esst_dir  = File.join(configatron.esst_dir, "nr100", na)
        cwd       = pwd
        mkdir_p esst_dir
        chdir esst_dir

        FileList[File.join(configatron.family_dir, "nr100", na, "*", "*")].select { |t|
          t.match(/(\d+)\/\1\.tem/)
        }.each do |tem_file|
          cp tem_file, "."
        end

        sh "ls -1 *.tem > tem_files.lst"

        (30..100).step(5) do |weight|
#          sh "ruby-1.9 /home/semin/ulla/bin/ulla -l tem_files.lst --cys 2 --weight #{weight} --output 0 -o ulla-#{na}-#{weight}.cnt"
#          sh "ruby-1.9 /home/semin/ulla/bin/ulla -l tem_files.lst --cys 2 --autosigma --weight #{weight} --output 1 -o ulla-#{na}-#{weight}.prb"
#          sh "ruby-1.9 /home/semin/ulla/bin/ulla -l tem_files.lst --cys 2 --autosigma --weight #{weight} --output 2 -o ulla-#{na}-#{weight}.log"
          sh "ruby-1.9 /home/semin/ulla/bin/ulla -l tem_files.lst --cys 2 --weight #{weight} --output 0 -o ulla-#{na}-#{weight}.cnt"
          sh "ruby-1.9 /home/semin/ulla/bin/ulla -l tem_files.lst --cys 2 --autosigma --weight #{weight} --output 1 -o ulla-#{na}-#{weight}.prb"
          sh "ruby-1.9 /home/semin/ulla/bin/ulla -l tem_files.lst --cys 2 --autosigma --weight #{weight} --output 2 -o ulla-#{na}-#{weight}.log"
        end

        chdir cwd
      end
    end # task :essts


    desc "Generate Fugue profile for each representative set of SCOP families"
    task :profiles => [:environment] do

      (20..100).step(20) do |si|
        #temporary filter!!!
        next if si != 90

        %w[dna rna].each do |na|
          %w[16 64 std].each do |env|
            cwd     = pwd
            est_dir = File.join(configatron.esst_dir, "rep#{si}", "#{na}#{env}")

            chdir esst_dir
            cp "allmat.#{na}#{env}.log.dat", "allmat.dat.log"
            system "melody -list templates.lst -c classdef.dat -s allmat.dat.log"
            chdir cwd
          end
        end
      end
    end


    desc "Generate a figure for each PDB structure"
    task :structure_figures => [:environment] do

      mkdir_p configatron.figure_dir

      pdb_files = Dir[configatron.pdb_dir.join("*.pdb").to_s]
      pdb_files.each_with_index do |pdb_file, i|
        stem    = File.basename(pdb_file, ".pdb")
        input   = Rails.root.join("tmp", "#{stem}.input")
        fig5    = configatron.figure_dir.join("#{stem}_5.png") # molscript cannot hangle a long input file name
        fig500  = configatron.figure_dir.join("#{stem}_500.png")
        fig100  = configatron.figure_dir.join("#{stem}_100.png")

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
    task :domain_only_figures => [:environment] do

      mkdir_p configatron.figure_dir

      scop_files = Dir[configatron.family_dir.join("full", "*", "*", "*.pdb").to_s]
      scop_files.each_with_index do |scop_file, i|
        stem    = File.basename(scop_file, ".pdb")
        input   = Rails.root.join("tmp", "#{stem}.molinput")
        fig5    = configatron.figure_dir.join("#{stem}_5.png") # molscript cannot hangle a long input file name
        fig500  = configatron.figure_dir.join("#{stem}_only_500.png")
        fig100  = configatron.figure_dir.join("#{stem}_only_100.png")

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
    task :domain_figures => [:environment] do

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
    task :interface_descriptor_file => [:environment] do

      File.open("./tmp/interface_descriptors.txt", "w") do |file|
        DomainInterface.find_each do |int|
          file.puts [int.id, *int.shape_descriptors].join(", ") if int.interface_atoms.size > 3
        end
      end
    end


    desc "Generate non-redundant protein-DNA/RNA chain sets for Nabal training"
    task :nr_chains => [:environment] do

      structures = Structure.untainted.max_resolution(3.0)

      %[dna rna].each do |na|
        File.open(Rails.root.join("tmp/#{na}_set.fasta"), 'w') do |na_set|
          structures.each_with_index do |structure, i|
            structure.aa_chains.each do |chain|
              if (chain.aa_residues.size > 30) && ((residue_size = chain.send("#{na}_binding_interface_residues").size) > 0)
                na_set.puts ">#{structure.pdb_code}_#{chain.chain_code}_#{residue_size}"
                na_set.puts chain.aa_residues.map(&:one_letter_code).join('')
              end
            end
            $logger.info ">>> Detecting #{na.upcase}-binding chain(s) from #{structure.pdb_code}: done (#{i+1}/#{structures.size})"
          end
        end

        # Run blastclust to make non-redundant protein-DNA/RNA chain sets
        cwd = pwd
        chdir Rails.root.join("tmp")
        sh "blastclust -i #{na}_set.fasta -o #{na}_set.cluster25 -L .9 -b F -p T -S 25"
        chdir cwd

        $logger.info ">> Running blastclust for non-redundant protein-#{na.upcase} chain sets: done"
      end
    end


    desc "Generate lists of non-redundant protein-DNA/RNA chain sets"
    task :nr_chain_lists => [:environment] do

      %w[dna rna].each do |na|
        na_set = Rails.root.join("tmp", "#{na}_set.cluster25")
        $logger.error "!!! #{na_set} does not exist" unless File.exists? na_set
        list_file = Rails.root.join("tmp", File.basename(na_set, ".cluster25") + ".list")

        File.open(list_file, "w") do |list|
          IO.foreach(na_set) do |line|
            unless line.empty?
              rep = line.chomp.split(/\s+/).sort { |x, y|
                x.split("_").last.to_i <=> y.split("_").last.to_i
              }.last
              pdb_code = rep.split("_")[0]
              chain_code = rep.split("_")[1]
              list.puts "#{pdb_code}_#{chain_code}"
            end
          end
        end
      end
    end


    desc "Generate PSSMs for each of non-redundant protein-DNA/RNA chain sets"
    task :pssms => [:environment] do

      blast_db = Rails.root.join("tmp", "nr100_24Jun09.clean.fasta")
      fmanager = ForkManager.new(configatron.max_fork)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        %w[dna rna].each do |na|
          na_list  = Rails.root.join("tmp", "#{na}_set.list")

          IO.foreach(na_list) do |line|
            fmanager.fork do
              ActiveRecord::Base.establish_connection(config)

              stem        = line.chomp
              pdb_code    = stem.split("_").first
              chain_code  = stem.split("_").last
              structure   = Structure.find_by_pdb_code(pdb_code.upcase)
              chain       = structure.models[0].chains.find_by_chain_code(chain_code)
              aa_residues = chain.aa_residues

              # create input fasta file
              File.open(Rails.root.join("tmp", "#{stem}.fasta"), "w") do |fasta|
                fasta.puts ">#{stem}"
                fasta.puts aa_residues.map(&:one_letter_code).join('')
              end

              # run PSI-Blast against NR100 and generate PSSMs
              cwd = pwd
              chdir Rails.root.join("tmp")
              system "blastpgp -i #{stem}.fasta -d #{blast_db} -e 0.01 -h 0.01 -j 5 -m 7 -o #{stem}.blast.xml -a 1 -C #{stem}.asnt -Q #{stem}.pssm -u 1 -J T -W 2"
              chdir cwd

              $logger.info ">>> Running PSI-Blast for #{stem}.pdb from #{na.upcase} set: done"
              ActiveRecord::Base.remove_connection
            end
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


    desc "Generate vectorized input features for Nabal traning & testing"
    task :input_features => [:environment] do

      require 'facets'

      window_size = 7
      radius      = window_size / 2

      %w[dna rna].each do |na|
        na_stem = "#{na}_set"
        na_list = Rails.root.join("tmp", "#{na_stem}.list")

        unless File.exists? na_list
          $logger.error "!!! Cannot find #{na_list}"
          exit 1
        end

        # read ESST files
        esst_file = Rails.root.join("tmp", "essts", na, "ulla-#{na}-60.log")

        unless File.exists? esst_file
          $logger.error "!!! Cannot find #{esst_file}"
          exit 1
        end

        essts = Bipa::Essts.new(esst_file).essts

        # divide traning and test sets
        # here, we use leave-one-out cross-validation
        total_set = IO.readlines(na_list)

        total_set.combination(1).each_with_index do |test_set, i|
          train_set = total_set - test_set

          %w[train test].each do |set_type|
            feature_file  = Rails.root.join("tmp", "#{na_stem}.#{set_type}#{i}")
            current_set   = set_type == 'train' ? train_set : test_set

            File.open(feature_file, 'w') do |feature|
              current_set.each do |entry|
                entry_stem      = entry.chomp
                pdb_code        = entry_stem.split("_").first
                chain_code      = entry_stem.split("_").last
                structure       = Structure.find_by_pdb_code(pdb_code.upcase)
                chain           = structure.models[0].chains.find_by_chain_code(chain_code)
                aa_residues     = chain.aa_residues
                nab_residues    = chain.send("#{na}_binding_interface_residues")
                nanb_residues   = aa_residues - nab_residues

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
                pssms     = []
                pssm_file = Rails.root.join("tmp", "#{entry_stem}.pssm")
                $logger.error "!!! #{pssm_file} does not exits" unless File.exists? pssm_file

                IO.foreach(pssm_file) do |line|
                  line.chomp!.strip!
                  if line =~ /^\d+\s+\w+/
                    columns = line.split(/\s+/)
                    pssms << NVector[*columns[2..21].map { |c| Float(c) }]
                  end
                end

                # create libSVM train file
                sel_residues = nab_residues + nanb_residues
                sel_residues.each_with_index do |residue, i|
                  # binding activily label
                  label = residue.on_interface? ? '+1' : '-1'

                  # sequence features
                  seq_features = (-radius..radius).map { |distance|
                    if (i + distance) >= 0 and aa_residues[i + distance]
                      aa_residues[i + distance].array20
                    else
                      AaResidue::ZeroArray20
                    end
                  }.flatten

                  # PSSM features
                  pssm_features = (-radius..radius).map { |distance|
                    if (i + distance) >= 0 and pssms[i + distance]
                      pssms[i + distance].to_a.map { |p| 1 / (1 + 1.0 / Math::E**-p) }
                    else
                      AaResidue::ZeroArray20
                    end
                  }.flatten

  #                # Distances between PSSM and corresponding ESST columns
  #                esst_features = essts.map { |esst|
  #                  (pssms[i] - esst.column(residue.one_letter_code)).to_a.map { |p| 1 / (1 + 1.0 / Math::E**-p) }
  #                }.flatten
  #
  #                # build atom KDTree
  #                kdtree      = Bipa::KDTree.new
  #                aa_atoms.each { |a| kdtree.insert(a) }

                  # Concatenate all the input features into total_features
                  total_features = seq_features + pssm_features

                  # Create libSVM input feature file
                  feature.puts label + " " + total_features.map_with_index { |f, i| "#{i + 1}:#{f}" }.join(' ')
                end
              end
            end
          end
        end
      end
    end

  end
end
