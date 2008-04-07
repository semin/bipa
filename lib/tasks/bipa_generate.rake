namespace :bipa do
  namespace :generate do

    desc "Generate PDB files for each SCOP family"
    task :family => [:environment] do

      family_sunids = ScopFamily.registered.map(&:sunid)
      fmanager      = ForkManager.new(MAX_FORK)

      refresh_dir(FAMILY_DIR)

      fmanager.manage do

        config = ActiveRecord::Base.remove_connection

        family_sunids.each_with_index do |family_sunid, i|

          fmanager.fork do

            ActiveRecord::Base.establish_connection(config)

            (10..100).step(10) do |si|

              nr_dir      = File.join(FAMILY_DIR, "nr#{si}")
              family      = ScopFamily.find_by_sunid(family_sunid)
              family_dir  = File.join(nr_dir, "#{family_sunid}")

              mkdir(family_dir)

              subfamilies = family.send("subfamilies#{si}")
              subfamilies.each do |subfamily|
                domain = subfamily.representative
                next if domain.nil?
                File.open(File.join(family_dir, "#{domain.sunid}.pdb"), "w") do |file|
                  file.puts domain.to_pdb
                end
              end
            end

            ActiveRecord::Base.remove_connection
          end

          ActiveRecord::Base.establish_connection(config)
          $logger.info("NR(#{nr_cutoff}): Creating PDB files for #{family_sunid}: done (#{i + 1}/#{family_sunids.size})")
        end
      end
    end

  end
end

