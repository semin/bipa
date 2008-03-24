namespace :bipa do
  namespace :fetch do

    require "logger"
    require "fileutils"

    include FileUtils

    $logger = Logger.new(STDOUT)

    task :default => [:all]

    desc "Fetch datasets for BIPA construction"
    task :all => [:pdb_remote, :scop]


    desc "Download protein-nucleic acid complexes from PDB ftp"
    task :pdb_remote => [:environment] do

      refresh_dir(PDB_DIR)

      require "net/ftp"

      Net::FTP.open("ftp.ebi.ac.uk") do |ftp|
        ftp.login("anonymous")
        ftp.chdir("/pub/databases/rcsb/pdb-remediated/")
        ftp.gettextfile("./derived_data/pdb_entry_type.txt",
                        File.join(PDB_DIR, "pdb_entry_type.txt"))
        $logger.info("Downloading pdb_entry_type.txt file: done")

        IO.readlines(File.join(PDB_DIR, "pdb_entry_type.txt")).each do |line|
          pdb_code, entry_type, exp_method = line.split(/\s+/)
          if entry_type == "prot-nuc"
            ftp.getbinaryfile("./data/structures/all/pdb/pdb#{pdb_code}.ent.gz",
                              File.join(PDB_DIR, "#{pdb_code}.pdb.gz"))
            $logger.info("Downloading #{pdb_code}: done")
          end
        end
      end

      cwd = pwd
      chdir(PDB_DIR)
      system("gzip -d *.gz")
      chdir(cwd)
      $logger.info("Unzipping downloaded PDB files: done")
    end


    desc "Fetch PDB datasets from local mirror"
    task :pdb_local => [:environment] do

      refresh_dir(PDB_DIR)
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
            if File.exist?(pdb_file)
              File.open(File.join(PDB_DIR, "#{pdb_code}.pdb"),'w') do |f|
                f.puts Zlib::GzipReader.open(pdb_file).readlines.join
              end
              $logger.info("Copying #{pdb_file} (#{i + 1}/#{pna_complexes.size}): done")
            else
              missings << pdb_code
            end
          end
        end
      end
      $logger.info("Total: #{pna_complexes.size - missings.size} files.\n" +
                   "Missing: #{missings.size} files")
    end


    desc "Fetch SCOP parseable files from MRC-LMB Web site"
    task :scop => [:environment] do

      refresh_dir(SCOP_DIR)

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
          puts "Downloading #{link}: done"
        end
      end
    end


#    desc "Get NCBI Taxonomy dataset from NCBI ftp"
#    task :taxonomy => [:environment] do
#      refresh_dir(BIPA_ENV[:TAXONOMY_DIR])
#
#      require 'net/ftp'
#
#      Net::FTP.open(BIPA_ENV[:NCBI_FTP]) do |ftp|
#        ftp.login('anonymous')
#        ftp.chdir(BIPA_ENV[:TAXONOMY_FTP])
#        ftp.nlst('tax*').each do |file|
#          ftp.getbinaryfile(file, File.join(BIPA_ENV[:TAXONOMY_DIR], file))
#          puts "Downloading #{file} to #{BIPA_ENV[:TAXONOMY_DIR]}: done"
#        end
#      end
#    end

  end
end
