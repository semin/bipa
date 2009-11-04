namespace :fuguena do
  namespace :run do

    desc "Run Ulla to generate ESSTs"
    task :ulla => [:environment] do

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do
        %w[dna rna].each do |na|
          ["std64", "#{na}128", "#{na}256"].each do |env|
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

                system "ls -1 ../*.tem | grep -v #{newtem} > temfiles.lst"

                (30..100).step(10) do |weight|
                  system "ulla -l temfiles.lst -c ../classdef.dat --autosigma --weight #{weight} --output 2 -o ulla-#{env}-#{weight}.lgd"
                end
                chdir esstdir
              end
              chdir cwd
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
          ["std64", "#{na}128", "#{na}256"].each do |env|
            fm.fork do
              cwd   = pwd
              tests = configatron.fuguena_dir.join("essts", na, env).children.select { |c| c.directory? }

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
                  system "melody -t #{tem} -c ../classdef.dat -s ulla-#{env}-60.lgd -o #{fam}-#{sunid}-#{env}-60.fug"
                end
              end

              chdir cwd
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
          ["std64", "#{na}128", "#{na}256"].each do |env|
            fm.fork do
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
                  system cmd
                end
                $logger.info "FUGUE-#{na.upcase}-#{env} search for #{test.basename}: done (#{i+1}/#{total})"
              end

              chdir cwd
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

  end
end

