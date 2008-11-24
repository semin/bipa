namespace :bipa do
  namespace :generate do

    desc "Generate full set of PDB files for each SCOP family"
    task :full_scop_pdb_files => [:environment] do

      %w[dna rna].each do |na|
        fmanager  = ForkManager.new(MAX_FORK)
        sunids    = ScopFamily.send("rpall_#{na}").map(&:sunid)
        full_dir  = File.join(FAMILY_DIR, "full", na)

        refresh_dir(full_dir) unless RESUME

        fmanager.manage do
          config = ActiveRecord::Base.remove_connection

          sunids.each_with_index do |sunid, i|
            fmanager.fork do
              ActiveRecord::Base.establish_connection(config)

              family      = ScopFamily.find_by_sunid(sunid)
              family_dir  = File.join(full_dir, "#{sunid}")

              mkdir_p(family_dir) unless File.exists? family_dir

              domains = family.leaves.select(&:"rpall_#{na}")
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
                dom_pdb   = File.join(SCOP_PDB_DIR, dom_sid[2..3], "#{dom_sid}.ent")

                if !File.size? dom_pdb
                  $logger.warn "!!! Cannot find #{dom_pdb} file"
                  exit 1
                end

                # Generate PDB file only for the first model in NMR structure using Bio::PDB
                File.open(File.join(family_dir, "#{domain.sunid}.pdb"), "w") do |f|
                  f.puts Bio::PDB.new(IO.read(dom_pdb)).models.first
                end

                #cp dom_pdb, File.join(family_dir, "#{domain.sunid}.pdb")
              end

              ActiveRecord::Base.remove_connection
              $logger.info ">>> Generating full set of PDB files for #{na.upcase} binding SCOP Family, #{sunid}: done (#{i + 1}/#{sunids.size})"
            end
          end
          ActiveRecord::Base.establish_connection(config)
        end
      end
    end


    desc "Generate non-redundant set of PDB files for each SCOP Family"
    task :nr_scop_pdb_files => [:environment] do

      %w[dna rna].each do |na|
        fmanager  = ForkManager.new(MAX_FORK)
        sunids    = ScopFamily.send("rpall_#{na}").map(&:sunid)
        full_dir  = File.join(FAMILY_DIR, "full", na)

        fmanager.manage do
          config = ActiveRecord::Base.remove_connection
          sunids.each_with_index do |sunid, i|
            fmanager.fork do
              ActiveRecord::Base.establish_connection(config)

              family = ScopFamily.find_by_sunid(sunid)

              (20..100).step(20) do |si|
                nr_dir      = File.join(FAMILY_DIR, "nr#{si}", na)
                family_dir  = File.join(nr_dir, "#{sunid}")

                mkdir_p family_dir

                subfamilies = family.send("nr#{si}_#{na}_subfamilies")
                subfamilies.each do |subfamily|
                  domain = subfamily.representative
                  next if domain.nil?

                  domain_pdb_file = File.join(full_dir, sunid.to_s, domain.sunid.to_s + '.pdb')

                  if !File.size? domain_pdb_file
                    $logger.warn "!!! Cannot find #{domain_pdb_file}"
                    exit 1
                  end

                  cp domain_pdb_file, family_dir
                end
              end
              ActiveRecord::Base.remove_connection
            end

            $logger.info ">>> Generating non-redundant PDB files for #{na.upcase} binding SCOP family, #{sunid}: done (#{i + 1}/#{sunids.size})"
            ActiveRecord::Base.establish_connection(config)
          end
        end
      end
    end


    desc "Generate PDB files for each Subfamily of each SCOP Family"
    task :sub_scop_pdb_files => [:environment] do

      %w[dna rna].each do |na|
        fmanager  = ForkManager.new(MAX_FORK)
        sunids    = ScopFamily.send("rpall_#{na}").map(&:sunid)
        sub_dir   = File.join(FAMILY_DIR, "sub", na)
        full_dir  = File.join(FAMILY_DIR, "full", na)

        refresh_dir(sub_dir) unless RESUME
        fmanager.manage do
          config = ActiveRecord::Base.remove_connection

          sunids.each_with_index do |sunid, i|
            fmanager.fork do
              ActiveRecord::Base.establish_connection(config)

              family      = ScopFamily.find_by_sunid(sunid)
              family_dir  = File.join(sub_dir, "#{sunid}")

              mkdir_p(family_dir)

              (20..100).step(20) do |si|
                nr_dir = File.join(family_dir, "nr#{si}")
                mkdir_p nr_dir

                subfamilies = family.send("nr#{si}_#{na}_subfamilies")
                subfamilies.each do |subfamily|
                  subfamily_dir = File.join(nr_dir, subfamily.id.to_s)
                  mkdir_p subfamily_dir

                  domains = subfamily.domains
                  domains.each do |domain|
                    domain_pdb_file = File.join(full_dir, sunid.to_s, domain.sunid.to_s + '.pdb')

                    if !File.exists?(domain_pdb_file)
                      $logger.warn ">>> SCOP Domain, #{domain.sunid} might be C-alpha only or having 'UNK' residues"
                      next
                    end
                    cp domain_pdb_file, subfamily_dir
                  end # domains.each
                end # subfamilies.each
              end # (20..100).step(20)

              $logger.info ">>> Generating PDB files for #{na.upcase} binding subfamilies of each SCOP Family, #{sunid}: done (#{i + 1}/#{sunids.size})"
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
        (10..100).step(10) do |si|
          next unless si == 90 # temporary skipping!!!

          rep_dir = File.join(ALIGNMENT_DIR, "rep#{si}")

          Dir.new(rep_dir).each do |dir|
            next if dir =~ /^\./

            family    = Scop.find_by_sunid(dir)
            alignment = family.send(:"rep#{si}_alignment")

            next unless alignment

            family_dir  = File.join(rep_dir, dir)
            tem_file    = File.join(family_dir, "baton.tem")

            next unless File.size? tem_file

            new_tem_file = File.join(family_dir, "baton_na.tem")
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

      refresh_dir(ESST_DIR) unless RESUME

      %w[dna rna].each do |na|
        (20..100).step(20) do |si|
          # CAUTION!!!
          if si != 80
            $logger.warn "!!! Sorry, skipped #{na}#{si} for the moment"
            next
          end

          nr_dir = File.join(FAMILY_DIR, "nr#{si}", na)

          %w[16 64 std].each do |env|
            est_dir = File.join(ESST_DIR, "nr#{si}", na, env)
            mkdir_p est_dir

            Dir.new(nr_dir).each do |dir|
              next if dir =~ /^\./ or dir !~ /^\d+$/

              tem     = File.join(nr_dir, dir, "#{dir}.tem")
              new_tem = File.join(est_dir, "#{dir}.tem")
              fam     = Scop.find_by_sunid(dir)
              ali     = fam.send(:"nr#{si}_#{na}_alignment")

              if ali && ali.sequences.map(&:domain).sum { |d| d.send(:"#{na}_interfaces").size } > 0
                cp(tem, new_tem) if File.exist?(tem)
              end
            end

            cp("#{na.upcase}#{env.upcase}_CLASSDEF".constantize, est_dir)

#            cwd = pwd
#            chdir est_dir
#            cp "classdef.#{na}#{env}.dat", "classdef.dat"
#            system "ls *.tem -1 > templates.lst"
#            system "subst --tem-list templates.lst --weight 100 --output 0"
#            system "subst --tem-list templates.lst --weight 100 --output 1 --outfile allmat.#{na}#{env}.prob.dat"
#            system "subst --tem-list templates.lst --weight 100 --output 2 --outfile allmat.#{na}#{env}.log.dat"
#            chdir cwd
          end
        end # (20..100).step(20)
      end
    end # task :essts


    desc "Generate Fugue profile for each representative set of SCOP families"
    task :profiles => [:environment] do

      (20..100).step(20) do |si|
        next if si != 90

        %w[dna rna].each do |na|
          %w[16 64 std].each do |env|
            cwd     = pwd
            est_dir = File.join(ESST_DIR, "rep#{si}", "#{na}#{env}")

            chdir esst_dir
            cp "allmat.#{na}#{env}.log.dat", "allmat.dat.log"
            system "melody -list templates.lst -c classdef.dat -s allmat.dat.log"
            chdir cwd
          end
        end
      end
    end


    desc "Generate PNG figure for each PDB files"
    task :structures_png => [:environment] do

      cwd = pwd
      chdir PDB_DIR

      Dir.new(PDB_DIR).each do |file|
        next if file =~ /^\./ or file !~ /\.pdb$/
        stem = file.match(/(\S{4})\.pdb/)[1]
        system  "molauto -notitle -nice #{stem}.pdb | " +
                "molscript -r | " +
                "perl -pi -e 's/^0 0 0\s+background.*$/1 1 1      background colour\n/g' | " +
                "render -png #{stem}.png"
      end

      chdir cwd
    end

  end
end
