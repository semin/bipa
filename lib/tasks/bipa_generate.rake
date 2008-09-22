namespace :bipa do
  namespace :generate do

    desc "Generate full set of PDB files for each SCOP family"
    task :full_scop_pdb_files => [:environment] do

      sunids    = ScopFamily.registered.find(:all, :select => "sunid").map(&:sunid)
      fmanager  = ForkManager.new(MAX_FORK)
      full_dir  = File.join(FAMILY_DIR, "full")

      refresh_dir(full_dir) unless RESUME

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        sunids.each_with_index do |sunid, i|

          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)

            family      = ScopFamily.find_by_sunid(sunid)
            family_dir  = File.join(full_dir, "#{sunid}")

            mkdir_p(family_dir) unless File.exists? family_dir

            domains = family.all_registered_leaf_children
            domains.each do |domain|
              domain_pdb_file = File.join(family_dir, "#{domain.sunid}.pdb")

              if File.size?(domain_pdb_file)
                $logger.warn("SKIP: #{domain_pdb_file} already exists!")
                next
              end

              if domain.has_unks? || domain.calpha_only?
                $logger.warn("SKIP: #{domain.sid} is C-alpha only or having some unknown residues")
                next
              end

              File.open(domain_pdb_file, "w") do |file|
                file.puts domain.to_pdb + "END\n"
              end
            end

            ActiveRecord::Base.remove_connection
            $logger.info("Generating full set of PDB files for SCOP Family, #{sunid}: done (#{i + 1}/#{sunids.size})")
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


    desc "Generate representative set of PDB files for each SCOP Family"
    task :rep_scop_pdb_files => [:environment] do

      sunids    = ScopFamily.registered.find(:all, :select => "sunid").map(&:sunid)
      fmanager  = ForkManager.new(MAX_FORK)
      full_dir  = File.join(FAMILY_DIR, "full")

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        sunids.each_with_index do |sunid, i|

          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)

            family = ScopFamily.find_by_sunid(sunid)

            (10..100).step(10) do |si|
              rep_dir     = File.join(FAMILY_DIR, "rep#{si}")
              family_dir  = File.join(rep_dir, "#{sunid}")

              mkdir_p(family_dir)

              subfamilies = family.send("rep#{si}_subfamilies")
              subfamilies.each do |subfamily|
                domain = subfamily.representative
                next if domain.nil?

                domain_pdb_file = File.join(full_dir, sunid.to_s, domain.sunid.to_s + '.pdb')
                raise "Cannot find #{domain_pdb_file}" if !File.exists?(domain_pdb_file)

                system("cp #{domain_pdb_file} #{family_dir}")
              end
            end
            ActiveRecord::Base.remove_connection
          end
          $logger.info("Generating representative PDB files for #{sunid}: done (#{i + 1}/#{sunids.size})")
          ActiveRecord::Base.establish_connection(config)
        end
      end
    end


    desc "Generate PDB files for each Subfamily of each SCOP Family"
    task :sub_scop_pdb_files => [:environment] do

      sunids    = ScopFamily.registered.find(:all, :select => "sunid").map(&:sunid)
      fmanager  = ForkManager.new(MAX_FORK)
      sub_dir   = File.join(FAMILY_DIR, "sub")
      full_dir  = File.join(FAMILY_DIR, "full")

      refresh_dir(sub_dir)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        sunids.each_with_index do |sunid, i|

          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)

            family      = ScopFamily.find_by_sunid(sunid)
            family_dir  = File.join(sub_dir, "#{sunid}")

            mkdir_p(family_dir)

            (10..100).step(10) do |si|
              rep_dir = File.join(family_dir, "rep#{si}")
              mkdir_p(rep_dir)

              subfamilies = family.send("rep#{si}_subfamilies")
              subfamilies.each do |subfamily|
                subfamily_dir = File.join(rep_dir, subfamily.id.to_s)
                mkdir_p(subfamily_dir)

                domains = subfamily.domains

                domains.each do |domain|
                  domain_pdb_file = File.join(full_dir, sunid.to_s, domain.sunid.to_s + '.pdb')

                  if !File.exists?(domain_pdb_file)
                    $logger.warn("Scop Domain, #{domain.sunid} might be C-alpha only or having 'UNK' residues")
                    next
                  end

                  system("cp #{domain_pdb_file} #{subfamily_dir}")
                end # domains.each
              end # subfamilies.each
            end # (10..100).step(10)

            $logger.info("Generating PDB files for subfamilies of each SCOP Family, #{sunid}: done (#{i + 1}/#{sunids.size})")
            ActiveRecord::Base.remove_connection
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


    desc "Generate simple (DNA/RNA) TEM file for each alignments"
    task :simple_tem_files => [:environment] do

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
          cp tem_file, new_tem_file

          alignment.sequences.each do |sequence|
            sunid = sequence.domain.sunid

            $logger.info "Annotating Protein-DNA/RNA interfaces of SCOP domain, #{sunid} ..."

            ext_tem = []

            sequence.positions.each_with_index do |position, pi|
              ext_tem << "\n" if pi != 0 and pi % 75 == 0

              case
              when position.gap?
                ext_tem << "-"
              when position.residue.send(:"binding_dna?")
                ext_tem << "D"
              when position.residue.send(:"binding_rna?")
                ext_tem << "R"
              when position.residue.send(:"on_surface?")
                ext_tem << "A"
              else
                ext_tem << "B"
              end
            end

            File.open(new_tem_file, "a") do |file|
              file.puts ">P1;#{sunid}"
              file.puts "extended solvent accessibility"
              file.puts ext_tem.join + "*"
            end
          end
        end
      end
    end


    desc "Generate extended (DNA/RNA) TEM file for each alignments"
    task :extended_tem_files => [:environment] do

      (10..100).step(10) do |si|
        rep_dir = File.join(ALIGNMENT_DIR, "rep#{si}")

        Dir.new(rep_dir).each do |dir|
          if dir =~ /^\./ then next end # skip if . or ..

          family    = Scop.find_by_sunid(dir)
          alignment = family.send(:"rep#{si}_alignment")

          unless alignment then next end # skip if there is no alignment

          family_dir  = File.join(rep_dir, dir)
          tem_file    = File.join(family_dir, "baton.tem")

          unless File.size? tem_file then next end # skip if there is no baton.tem file

          %w(dna rna).each do |na|
            new_tem_file = File.join(family_dir, "baton_#{na}.tem")
            cp tem_file, new_tem_file

            alignment.sequences.each do |sequence|

              sunid = sequence.domain.sunid
              na_up = na.upcase

              $logger.info "Annotating Protein-#{na_up} interactions of SCOP family, #{sunid}..."

              hbond_base_tem        = []
              hbond_sugar_tem       = []
              hbond_phosphate_tem   = []
              whbond_base_tem       = []
              whbond_sugar_tem      = []
              whbond_phosphate_tem  = []
              vdw_contact_base_tem      = []
              vdw_contact_sugar_tem     = []
              vdw_contact_phosphate_tem = []

              sequence.positions.each_with_index do |position, pi|
                if pi != 0 and pi % 75 == 0
                  hbond_base_tem        << "\n"
                  hbond_sugar_tem       << "\n"
                  hbond_phosphate_tem   << "\n"
                  whbond_base_tem       << "\n"
                  whbond_sugar_tem      << "\n"
                  whbond_phosphate_tem  << "\n"
                  vdw_contact_base_tem      << "\n"
                  vdw_contact_sugar_tem     << "\n"
                  vdw_contact_phosphate_tem << "\n"
                end

                if position.gap?
                  hbond_base_tem        << "-"
                  hbond_sugar_tem       << "-"
                  hbond_phosphate_tem   << "-"
                  whbond_base_tem       << "-"
                  whbond_sugar_tem      << "-"
                  whbond_phosphate_tem  << "-"
                  vdw_contact_base_tem      << "-"
                  vdw_contact_sugar_tem     << "-"
                  vdw_contact_phosphate_tem << "-"
                  next
                else
                  hbond_base_tem        << (position.residue.send(:"hbonding_#{na}_base?")         ? "T" : "F")
                  hbond_sugar_tem       << (position.residue.send(:"hbonding_#{na}_sugar?")        ? "T" : "F")
                  hbond_phosphate_tem   << (position.residue.send(:"hbonding_#{na}_phosphate?")    ? "T" : "F")
                  whbond_base_tem       << (position.residue.send(:"whbonding_#{na}_base?")        ? "T" : "F")
                  whbond_sugar_tem      << (position.residue.send(:"whbonding_#{na}_sugar?")       ? "T" : "F")
                  whbond_phosphate_tem  << (position.residue.send(:"whbonding_#{na}_phosphate?")   ? "T" : "F")
                  vdw_contact_base_tem      << (position.residue.send(:"vdw_contacting_#{na}_base?")       ? "T" : "F")
                  vdw_contact_sugar_tem     << (position.residue.send(:"vdw_contacting_#{na}_sugar?")      ? "T" : "F")
                  vdw_contact_phosphate_tem << (position.residue.send(:"vdw_contacting_#{na}_phosphate?")  ? "T" : "F")
                end
              end

              File.open(new_tem_file, "a") do |file|
                file.puts ">P1;#{sunid}"
                file.puts "hydrogen bond to #{na_up} base"
                file.puts hbond_base_tem.join + "*"

                file.puts ">P1;#{sunid}"
                file.puts "hydrogen bond to #{na_up} sugar"
                file.puts hbond_sugar_tem.join + "*"

                file.puts ">P1;#{sunid}"
                file.puts "hydrogen bond to #{na_up} phosphate"
                file.puts hbond_phosphate_tem.join + "*"

                file.puts ">P1;#{sunid}"
                file.puts "water-mediated hydrogen bond to #{na_up} base"
                file.puts whbond_base_tem.join + "*"

                file.puts ">P1;#{sunid}"
                file.puts "water-mediated hydrogen bond to #{na_up} sugar"
                file.puts whbond_sugar_tem.join + "*"

                file.puts ">P1;#{sunid}"
                file.puts "water-mediated hydrogen bond to #{na_up} phosphate"
                file.puts whbond_phosphate_tem.join + "*"

                file.puts ">P1;#{sunid}"
                file.puts "van der Waals vdw_contact to #{na_up} base"
                file.puts vdw_contact_base_tem.join + "*"

                file.puts ">P1;#{sunid}"
                file.puts "van der Waals vdw_contact to #{na_up} sugar"
                file.puts vdw_contact_sugar_tem.join + "*"

                file.puts ">P1;#{sunid}"
                file.puts "van der Waals vdw_contact to #{na_up} phosphate"
                file.puts vdw_contact_phosphate_tem.join + "*"
              end
            end
          end
        end
      end
    end


    desc "Generate ESSTs for each representative set of SCOP families"
    task :essts => [:environment] do

      refresh_dir ESST_DIR

      (10..100).step(10) do |si|
        rep         = "rep#{si}"
        ali_dir     = File.join(ALIGNMENT_DIR, rep)
        est_dir     = File.join(ESST_DIR, rep)

        %w(dna rna).each do |na|
          est_na_dir = File.join(est_dir, na)
          mkdir_p est_na_dir

          Dir.new(ali_dir).each do |dir|
            if dir =~ /^\./ then next end # skip if . or ..
            na_tem      = File.join(ali_dir, dir, "baton_#{na}.tem")
            new_na_tem  = File.join(est_na_dir, "#{dir}.tem")
            cp na_tem, new_na_tem if File.exist? na_tem
          end

        end # %w(dna rna).each
      end # (10..100).step(10)
    end # task :essts


    desc "Generate ESSTs for each representative set of SCOP families"
    task :simple_essts => [:environment] do

      refresh_dir ESST_DIR

      (10..100).step(10) do |si|
        next unless si == 90 # temporar skipping!!!

        rep     = "rep#{si}"
        ali_dir = File.join(ALIGNMENT_DIR, rep)
        est_dir = File.join(ESST_DIR, rep)
        mkdir_p est_dir

        Dir.new(ali_dir).each do |dir|
          if dir =~ /^\./ then next end # skip if . or ..
          na_tem      = File.join(ali_dir, dir, "baton_na.tem")
          new_na_tem  = File.join(est_dir, "#{dir}.tem")
          cp na_tem, new_na_tem if File.exist? na_tem
        end
      end # (10..100).step(10)
    end # task :essts

  end
end
