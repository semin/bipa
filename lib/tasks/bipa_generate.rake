namespace :bipa do
  namespace :generate do

    desc "Generate PDB files for each SCOP family"
    task :pdb_files => [:environment] do

      family_sunids = ScopFamily.registered.find(:all).map(&:sunid)
      fmanager      = ForkManager.new(MAX_FORK)
      full_dir      = File.join(FAMILY_DIR, "full")
      sub_dir       = File.join(FAMILY_DIR, "sub")

      refresh_dir(full_dir)
      refresh_dir(sub_dir)

      fmanager.manage do

        config = ActiveRecord::Base.remove_connection

        family_sunids.each_with_index do |family_sunid, i|

          fmanager.fork do

            ActiveRecord::Base.establish_connection(config)

            family = ScopFamily.find_by_sunid(family_sunid)

            # for a full set
            family_dir = File.join(full_dir, "#{family_sunid}")
            mkdir_p(family_dir)

            domains = family.all_registered_leaf_children
            domains.each do |domain|
              File.open(File.join(family_dir, "#{domain.sunid}.pdb"), "w") do |file|
                file.puts domain.to_pdb + "END\n"
              end
            end
            $logger.info("Generating full set of PDB files for SCOP Family, #{family_sunid}: done (#{i + 1}/#{family_sunids.size})")

            # for individual subfamily set
            family_dir = File.join(sub_dir, "#{family_sunid}")
            mkdir_p(family_dir)

            (10..100).step(10) do |si|
              rep_dir = File.join(family_dir, si.to_s)
              mkdir_p(rep_dir)

              subfamilies = family.send("rep#{si}_subfamilies")
              subfamilies.each do |subfamily|

                subfamily_dir = File.join(rep_dir, subfamily.id.to_s)
                mkdir_p(subfamily_dir)

                domains = subfamily.domains
                domains.each do |domain|
                  domain_pdb_file = File.join(full_dir, family_sunid, domain.sunid.to_s + '.pdb')
                  raise "Cannot find #{domain_pdb_file}" unless File.exists?(domain_pdb_file)

                  system("cp #{domain_pdb_file} #{subfamily_dir}")
#                  File.open(File.join(family_dir, "#{domain.sunid}.pdb"), "w") do |file|
#                    file.puts domain.to_pdb + "END\n"
#                  end
                end # domains.each
              end # subfamilies.each
            end # (10..100).step(10)
            $logger.info("Generating full set of PDB files for every Subfamily, #{family_sunid}: done (#{i + 1}/#{family_sunids.size})")


            # for non-redundant sets
            (10..100).step(10) do |si|

              nr_dir      = File.join(FAMILY_DIR, "nr#{si}")
              family_dir  = File.join(nr_dir, "#{family_sunid}")

              mkdir_p(family_dir)

              subfamilies = family.send("subfamilies#{si}")
              subfamilies.each do |subfamily|

                domain = subfamily.representative
                next if domain.nil?

                domain_pdb_file = File.join(full_dir, family_sunid, domain.sunid.to_s + '.pdb')
                raise "Cannot find #{domain_pdb_file}" unless File.exists?(domain_pdb_file)

                system("cp #{domain_pdb_file} #{family_dir}")
#                File.open(File.join(family_dir, "#{domain.sunid}.pdb"), "w") do |file|
#                  file.puts domain.to_pdb
#                end
              end
              $logger.info("NR(#{si}): Copying PDB files for #{family_sunid}: done (#{i + 1}/#{family_sunids.size})")
            end

            ActiveRecord::Base.remove_connection
          end
          ActiveRecord::Base.establish_connection(config)
        end
      end
    end

  end
end
