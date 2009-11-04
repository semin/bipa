namespace :nabal do
  namespace :generate do

    desc "Generate non-redundant protein-DNA/RNA chain sets for Nabal training"
    task :nrchains => [:environment] do

      structures = Structure.untainted.max_resolution(3.0)

      %w[dna rna].each do |na|
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
        sh "blastclust -i #{na}_set.fasta -o #{na}_set.cluster30 -L .9 -b F -p T -S 30"
        chdir cwd

        $logger.info ">> Running blastclust for non-redundant protein-#{na.upcase} chain sets: done"
      end
    end


    desc "Generate lists of non-redundant protein-DNA/RNA chain sets"
    task :nrchainlists => [:environment] do

      %w[dna rna].each do |na|
        na_set = Rails.root.join("tmp", "#{na}_set.cluster30")
        $logger.error "!!! #{na_set} does not exist" unless File.exists? na_set
        list_file = Rails.root.join("tmp", File.basename(na_set, ".cluster30") + ".list")

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
          nalist  = Rails.root.join("tmp", "#{na}_set.list")

          IO.foreach(nalist) do |line|
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


    desc "Generate input feature statistics for Nabal"
    task :input_stats => [:environment] do

      %w[dna rna].each do |na|
        nastem      = "#{na}_set"
        nalist      = configatron.nabal_dir + "#{nastem}.list"
        nrchains    = IO.readlines(nalist).map(&:chomp)
        interfaces  = []
        surfaces    = []
        cores       = []

        nrchains.each_with_index do |nrchain, i|
          $logger.info "Processing #{nrchain} of #{na.upcase} set (#{i+1}/#{nrchains.size})"

          pdb_code        = nrchain.split("_").first
          chain_code      = nrchain.split("_").last
          structure       = Structure.find_by_pdb_code(pdb_code.upcase)
          chain           = structure.models[0].chains.find_by_chain_code(chain_code)
          aa_residues     = chain.aa_residues
          nab_residues    = chain.send("#{na}_binding_interface_residues")
          nanb_residues   = aa_residues - nab_residues
          kdtree   = Bipa::KDTree.new
          aa_residues.each { |r| r.atoms.each { |c| kdtree.insert(c) } }

          aa_residues.each do |residue|
            # USR descriptors
            ca = residue.atoms.find_by_atom_name('CA')

            if ca.nil?
              $logger.warn "Skip #{pdb_code}/#{chain_code}/#{i}/#{residue.residue_name}, no CA!"
              next
            end

            ncas          = kdtree.neighbors(ca, 12).map(&:point)
            usr_features  = AtomSet.new(ncas).shape_descriptors.to_a

            if residue.on_interface?
              interfaces << usr_features
            elsif residue.on_surface?
              surfaces << usr_features
            else
              cores << usr_features
            end
          end
        end

        File.open("#{nastem}-usr-interfaces.csv", 'w') do |f|
          interfaces.each { |i| f.puts i.join(", ") }
        end
        File.open("#{nastem}-usr-surfaces.csv", 'w') do |f|
          surfaces.each { |i| f.puts i.join(", ") }
        end
        File.open("#{nastem}-usr-cores.csv", 'w') do |f|
          cores.each { |i| f.puts i.join(", ") }
        end
      end
    end


    desc "Generate vectorized input features for Nabal traning & testing"
    task :input_features => [:environment] do

      require "facets"

      winsize = 7
      radius  = winsize / 2

      %w[dna rna].each do |na|
        nastem    = "#{na}_set"
        nalist    = configatron.nabal_dir + "#{nastem}.list"
        iff       = configatron.nabal_dir + "#{nastem}.input"
        nrchains  = IO.readlines(nalist).map(&:chomp)

        File.open(iff, 'w') do |feature|
          nrchains.each_with_index do |nrchain, i|
            $logger.info "Extracting input features from #{nrchain} of #{na.upcase} set (#{i+1}/#{nrchains.size})"

            pdb_code        = nrchain.split("_").first
            chain_code      = nrchain.split("_").last
            structure       = Structure.find_by_pdb_code(pdb_code.upcase)
            chain           = structure.models[0].chains.find_by_chain_code(chain_code)
            aa_residues     = chain.aa_residues
            nab_residues    = chain.send("#{na}_binding_interface_residues")
            nanb_residues   = aa_residues - nab_residues
            kdtree          = Bipa::KDTree.new

            aa_residues.each { |r| r.atoms.each { |c| kdtree.insert(c) } }

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
            pssm_file = configatron.nabal_dir.join("blast", "#{nrchain}.pssm")
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
            sel_residues.each do |residue|
              # index
              i = aa_residues.index(residue)

              # binding activily label
              label = residue.on_interface? ? '+1' : '-1'

              #
              # 1-Dimensional features
              #
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
                  pssms[i + distance].to_a
                else
                  AaResidue::ZeroArray20
                end
              }.flatten

              pssm_norm_features = pssm_features.map { |p| 1 / (1 + 1.0 / Math::E**-p) }

              #
              # 3-dimensional features from here!!!
              #

              # SSE
              sse_features = if residue.helix?
                               [1, 0, 0]
                             elsif residue.beta_sheet?
                               [0, 1, 0]
                             else
                               [0, 0, 1]
                             end

              # ASA
              asa_feature = [residue.relative_unbound_asa]

              # Spatial neighbors

              # USR descriptors
              ca = residue.atoms.find_by_atom_name('CA')

              if ca.nil?
                $logger.warn "Skip #{pdb_code}/#{chain_code}/#{i}/#{residue.residue_name}, no CA!"
                next
              end

              ncas          = kdtree.neighbors(ca, 12).map(&:point)
              usr_features  = AtomSet.new(ncas).shape_descriptors.to_a

              # Concatenate all the input features into total_features
              total_features = seq_features + pssm_features + sse_features + asa_feature + usr_features

              # Create libSVM input feature file
              feature.puts label + " " + total_features.map_with_index { |f, i| "#{i + 1}:#{f}" }.join(' ')
            end
          end
        end
      end
    end

  end
end
