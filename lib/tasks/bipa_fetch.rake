namespace :bipa do
  namespace :fetch do

    include FileUtils

    desc "Download protein-nucleic acid complexes from PDB ftp"
    task :pdb_remote => [:environment] do

      refresh_dir PDB_DIR

      require "net/ftp"

      Net::FTP.open("ftp.ebi.ac.uk") do |ftp|
        ftp.login "anonymous"
        ftp.chdir "/pub/databases/rcsb/pdb-remediated/"
        ftp.gettextfile("./derived_data/pdb_entry_type.txt", File.join(PDB_DIR, "pdb_entry_type.txt"))

        $logger.info "Downloading pdb_entry_type.txt file: done"

        IO.foreach(File.join(PDB_DIR, "pdb_entry_type.txt")) do |line|
          pdb_code, entry_type, exp_method = line.split(/\s+/)

          if entry_type == "prot-nuc"
            ftp.getbinaryfile("./data/structures/all/pdb/pdb#{pdb_code}.ent.gz", File.join(PDB_DIR, "#{pdb_code}.pdb.gz"))

            $logger.info("Downloading #{pdb_code}: done")
          end
        end
      end

      cwd = pwd
      chdir PDB_DIR
      system "gzip -d *.gz"
      chdir cwd

      $logger.info "Unzipping downloaded PDB files: done"
    end


    desc "Copy protein-nucleic acid complexes from local mirror"
    task :pdb_local => [:environment] do

      refresh_dir PDB_DIR
      pna_complexes = []

      IO.foreach(File.join(PDB_MIRROR_DIR, PDB_ENTRY_FILE)) do |line|
        pdb_code, entry_type, exp_method = line.chomp.split(/\s+/)
        pna_complexes << pdb_code if entry_type == "prot-nuc"
      end

      missings = []
      fmanager = ForkManager.new(MAX_FORK)

      fmanager.manage do
        pna_complexes.each_with_index do |pdb_code, i|
          fmanager.fork do
            pdb_file = File.join(PDB_MIRROR_DIR, "./data/structures/all/pdb/pdb#{pdb_code}.ent.gz")

            if File.size?(pdb_file)
              system "gzip -cd #{pdb_file} > #{File.join(PDB_DIR, pdb_code + '.pdb')}"
              $logger.info "Unzipping #{pdb_file} (#{i + 1}/#{pna_complexes.size}): done"
            else
              missings << pdb_code
            end
          end
        end
      end
      $logger.info "Total: #{pna_complexes.size - missings.size} files.\n" + "Missing: #{missings.size} files"
    end


    desc "Fetch SCOP parseable files from MRC-LMB Web site"
    task :scop => [:environment] do

      refresh_dir SCOP_DIR

      require "open-uri"
      require "hpricot"

      links = Hash.new(0)

      Hpricot(open(SCOP_URI)).search("//a") do |link|
        if link['href'] && link['href'] =~ /(dir\S+)\_(\S+)/
          stem, version = $1, $2.to_f
          links[stem] = version if links[stem] < version
        end
      end

      links.each do |stem, version|
        link = "#{stem}_#{version}"
        File.open(File.join(SCOP_DIR, link), 'w') do |f|
          f.puts open(SCOP_URI + "/#{link}").read
          $logger.info ">>> Downloading #{link}: done"
        end
      end
    end


    desc "Fetch GO related files"
    task :go => [:environment] do

      refresh_dir GO_DIR

      # Download GO-PDB mapping file from EBI
      require "net/ftp"

      Net::FTP.open("ftp.ebi.ac.uk") do |ftp|
        ftp.login "anonymous"
        ftp.chdir "/pub/databases/GO/goa/PDB/"
        ftp.getbinaryfile("./gene_association.goa_pdb.gz", File.join(GO_DIR, "gene_association.goa_pdb.gz"))

        $logger.info ">>> Downloading gene_association.goa_pdb.gz: done"
      end

      cwd = pwd
      chdir GO_DIR
      system "gzip -d *.gz"
      chdir cwd

      $logger.info ">>> Uncompressing gene_association.goa_pdb.gz: done"

      # Download GO.obo file from GO Web
      require "open-uri"

      File.open(File.join(GO_DIR, 'gene_ontology_edit.obo'), 'w') do |f|
        f.puts open(GO_OBO_URI).read
        $logger.info ">>> Downloading #{GO_OBO_URI}: done"
      end
    end


    desc "Fetch NCBI taxonomy files"
    task :taxonomy => [:environment] do

      refresh_dir TAXONOMY_DIR

      require "net/ftp"

      Net::FTP.open("ftp.ncbi.nih.gov") do |ftp|
        ftp.login "anonymous"
        ftp.chdir "/pub/taxonomy/"
        ftp.getbinaryfile("./taxdump.tar.gz", File.join(TAXONOMY_DIR, 'taxdump.tar.gz'))

        $logger.info ">>> Downloading taxdump.tar.gz: done"
      end

      cwd = pwd
      chdir TAXONOMY_DIR
      system "tar xvzf *.tar.gz"
      chdir cwd

      $logger.info ">>> Uncompressing taxdump.tar.gz: done"
    end

  end
end
