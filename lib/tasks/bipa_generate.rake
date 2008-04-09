namespace :bipa do
  namespace :generate do

    desc "Generate PDB files for each SCOP family"
    task :pdb_files => [:environment] do


      family_sunids = ScopFamily.registered.find(:all).map(&:sunid)
      fmanager      = ForkManager.new(MAX_FORK)
      full_dir      = File.join(FAMILY_DIR, "full")

      refresh_dir(full_dir)

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
              mid_stem = domain.sid[2..3]
              domain_pdb_file = File.join(SCOP_PDB_DIR, mid_stem, "#{domain.sid}.ent")
              raise "Cannot find #{domain_pdb_file}" unless File.exists?(domain_pdb_file)
              system("cp #{domain_pdb_file} #{File.join(family_dir, domain.sunid.to_s + '.pdb')}")
            end
            $logger.info("Copying PDB files for SCOP Family, #{family_sunid}: done (#{i + 1}/#{family_sunids.size})")

#            # for non-redundant sets
#            (10..100).step(10) do |si|
#
#              nr_dir      = File.join(FAMILY_DIR, "nr#{si}")
#              family_dir  = File.join(nr_dir, "#{family_sunid}")
#
#              mkdir_p(family_dir)
#
#              subfamily = family.send("subfamily#{si}")
#              repdomain = subfamily.representative
#
#              next if domain.nil?
#
#              File.open(File.join(family_dir, "#{domain.sunid}.pdb"), "w") do |file|
#                file.puts domain.to_pdb
#              end
#
#              $logger.info("NR(#{si}): Creating PDB files for #{family_sunid}: done (#{i + 1}/#{family_sunids.size})")
#            end

            ActiveRecord::Base.remove_connection
          end

          ActiveRecord::Base.establish_connection(config)
        end
      end
    end

  end
end
