namespace :bipa do
  namespace :fetch do

    desc "Download protein-nucleic acid complexes from PDB ftp"
    task :pdbremote => [:environment] do

      refresh_dir configatron.pdb_dir

      require "net/ftp"

      Net::FTP.open("ftp.ebi.ac.uk") do |ftp|
        ftp.login "anonymous"
        ftp.chdir "/pub/databases/rcsb/pdb-remediated/"
        ftp.gettextfile("./derived_data/pdb_entry_type.txt", File.join(configatron.pdb_dir, "pdb_entry_type.txt"))

        $logger.info ">>> Downloading pdb_entry_type.txt file: done"

        IO.foreach(File.join(configatron.pdb_dir, "pdb_entry_type.txt")) do |line|
          pdb_code, entry_type, exp_method = line.split(/\s+/)

          if entry_type == "prot-nuc"
            ftp.getbinaryfile("./data/structures/all/pdb/pdb#{pdb_code}.ent.gz", File.join(configatron.pdb_dir, "#{pdb_code}.pdb.gz"))

            $logger.info ">>> Downloading #{pdb_code}: done"
          end
        end
      end

      cwd = pwd
      chdir configatron.pdb_dir
      system "gzip -d *.gz"
      chdir cwd

      $logger.info ">>> Unzipping downloaded PDB files: done"
    end


    desc "Copy protein-nucleic acid complexes from local mirror"
    task :pdblocal => [:environment] do

      refresh_dir configatron.pdb_dir
      pdb_codes = []

      IO.foreach(File.join(configatron.pdb_mirror_dir, configatron.pdb_entry_file)) do |line|
        pdb_code, entry_type, exp_method = line.chomp.split(/\s+/)
        pdb_codes << pdb_code if entry_type == "prot-nuc"
      end

      missings = []

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do
        pdb_codes.each_with_index do |pdb_code, i|
          pdb_file = File.join(configatron.pdb_mirror_dir, "./data/structures/all/pdb/pdb#{pdb_code}.ent.gz")

          if File.size?(pdb_file)
            fm.fork do
              system "gzip -cd #{pdb_file} > #{File.join(configatron.pdb_dir, pdb_code + '.pdb')}"
              $logger.info "Unzipping #{pdb_file}: done (#{i+1}/#{pdb_codes.size})"
            end
          else
            missings << pdb_code
          end
        end
        $logger.info "Total: #{pdb_codes.size - missings.size} files.\n" + "Missing: #{missings.size} files"
      end
    end


    desc "Fetch SCOP parseable files from MRC-LMB Web site"
    task :scop => [:environment] do

      refresh_dir configatron.scop_dir

      require "uri"
      require "hpricot"

      links = Hash.new(0)

      Hpricot(open(configatron.scop_uri)).search("//a") do |link|
        if link['href'] && link['href'] =~ /(dir\S+)\_(\S+)/
          stem, version = $1, $2.to_f
          links[stem] = version if links[stem] < version
        end
      end

      links.each do |stem, version|
        link = "#{stem}_#{version}"
        File.open(File.join(configatron.scop_dir, link), 'w') do |f|
          f.puts open(configatron.scop_uri + "/#{link}").read
          $logger.info ">>> Downloading #{link}: done"
        end
      end
    end


    desc "Fetch GO related files"
    task :go => [:environment] do

      refresh_dir configatron.go_dir

      File.open(File.join(configatron.go_dir, 'gene_ontology_edit.obo'), 'w') do |f|
        f.puts open(configatron.go_obo_uri).read
        $logger.info ">>> Downloading #{configatron.go_obo_uri}: done"
      end

      # Download GO-PDB mapping file from EBI
      system "wget ftp://ftp.ebi.ac.uk/pub/databases/GO/goa/PDB/gene_association.goa_pdb.gz -P#{configatron.go_dir}"
      $logger.info ">>> Downloading gene_association.goa_pdb.gz: done"

      cwd = pwd
      chdir configatron.go_dir
      system "gzip -d *.gz"
      chdir cwd

      $logger.info ">>> Uncompressing gene_association.goa_pdb.gz: done"
    end


    desc "Fetch NCBI taxonomy files"
    task :ncbitax => [:environment] do

      refresh_dir configatron.taxonomy_dir

      require "net/ftp"

      Net::FTP.open("ftp.ncbi.nih.gov") do |ftp|
        ftp.login "anonymous"
        ftp.chdir "/pub/taxonomy/"
        ftp.getbinaryfile("./taxdump.tar.gz", File.join(configatron.taxonomy_dir, 'taxdump.tar.gz'))
        $logger.info ">>> Downloading taxdump.tar.gz: done"
      end

      cwd = pwd
      chdir configatron.taxonomy_dir
      system "tar xvzf *.tar.gz"
      chdir cwd
      $logger.info ">>> Uncompressing taxdump.tar.gz: done"
    end

  end
end
