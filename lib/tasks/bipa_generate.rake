namespace :bipa do
  namespace :generate do

    desc "Generate full set of PDB files for each SCOP family"
    task :full_scop_pdb_files => [:environment] do

      sunids    = ScopFamily.registered.find(:all, :select => "sunid").map(&:sunid)
      fmanager  = ForkManager.new(MAX_FORK)
      full_dir  = File.join(FAMILY_DIR, "full")

      refresh_dir(full_dir)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        sunids.each_with_index do |sunid, i|

          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)

            family      = ScopFamily.find_by_sunid(sunid)
            family_dir  = File.join(full_dir, "#{sunid}")

            mkdir_p(family_dir)

            domains = family.all_registered_leaf_children
            domains.each do |domain|
              next if domain.has_unks? || domain.calpha_only?

              File.open(File.join(family_dir, "#{domain.sunid}.pdb"), "w") do |file|
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
                raise "Cannot find #{domain_pdb_file}" unless File.exists?(domain_pdb_file)

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

  end
end
