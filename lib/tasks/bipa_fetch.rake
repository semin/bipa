namespace :bipa do
  namespace :fetch do
  
    require "fileutils"
    require "net/ftp"
    require "open-uri"
    require "hpricot"
    require "logger"
    
    include FileUtils
    
    $logger = Logger.new(STDOUT)

    task :default => [:all]

    desc "Fetch datasets for BIPA construction"
    task :all => [:pdb_remote, :scop]


    desc "Download protein-nucleic acid complexes from PDB ftp"
    task :pdb_remote => [:environment] do

      Net::FTP.open(BIPA_ENV[:PDB_FTP]) do |ftp|
        ftp.login "anonymous"
        ftp.chdir BIPA_ENV[:PDB_EBI_DIR]
        ftp.chdir BIPA_ENV[:PDB_ZIPPED_DIR]
        files = ftp.nlis("*.ent.gz")
        files.each_with_index do |file, i|
          ftp.getbinaryfile(file, File.join(BIPA_ENV[:PDB_DIR], file))
          $logger.info "Downloading #{file}: done (#{i+1}/#{files.size})"
        end
      end
      
      cwd = pwd
      chdir BIPA_ENV[:PDB_DIR]
      system "gzip -d *.gz"
      chdir cwd
      $logger.info "Unzipping downloaded PDB files: done"
    end
    
    
    desc "Fetch PDB datasets from local mirror"
    task :pdb_local => [:environment] do
      
      refresh_dir BIPA_ENV[:PDB_DIR]
      selected_pdbs = []

      IO.foreach(File.join(BIPA_ENV[:PDB_MIRROR_DIR],
                           BIPA_ENV[:PDB_ENTRY_TYPE_FILE])) do |line|
        pdb_code, entry_type, exp_method = line.chomp.split(/\s+/)
        if entry_type == BIPA_ENV[:ENTRY_TYPE]
          selected_pdbs << pdb_code.upcase
        end
      end

      missing_files = []
      pdb_total = selected_pdbs.size
      fm = ForkManager.new(BIPA_ENV[:MAX_FORK])

      fm.manage do
        selected_pdbs.each_with_index do |pdb, i|
          fm.fork do
            pdb_file = File.join(BIPA_ENV[:PDB_MIRROR_DIR],
                                 BIPA_ENV[:PDB_STRUCTURE_DIR],
                                 "pdb#{pdb.downcase}.ent.gz")
            if File.exist?(pdb_file)
              File.open(File.join(BIPA_ENV[:PDB_DIR],
                                  "#{pdb.downcase}.pdb"),'w') do |f|
                f.puts Zlib::GzipReader.open(pdb_file).readlines.join
              end
              puts  "Copying #{pdb} PDB file " +
                    "(#{i + 1}/#{pdb_total}): done"
            else
              missing_files << ent
            end
          end
        end
      end
    end


    desc "Get SCOP dataset from MRC-LMB Web site"
    task :scop => [:environment] do

      refresh_dir BIPA_ENV[:SCOP_DIR]

      
      Hpricot(open(BIPA_ENV[:SCOP_URI])).search("//a") do |link|
        if (link['href'] && link['href'] =~ /(dir\.\S+)/)
          File.open(File.join(BIPA_ENV[:PRESCOP_DIR],
                              link['href']), 'w') do |f|
            f.puts open(BIPA_ENV[:SCOP_URI] + "/#{link['href']}").read
            puts "Downloading #{link['href']}: done"
          end
        end
      end
    end
    

    desc "Get NCBI Taxonomy dataset from NCBI ftp"
    task :taxonomy => [:environment] do
      refresh_dir(BIPA_ENV[:TAXONOMY_DIR])

      require 'net/ftp'

      Net::FTP.open(BIPA_ENV[:NCBI_FTP]) do |ftp|
        ftp.login('anonymous')
        ftp.chdir(BIPA_ENV[:TAXONOMY_FTP])
        ftp.nlst('tax*').each do |file|
          ftp.getbinaryfile(file, File.join(BIPA_ENV[:TAXONOMY_DIR], file))
          puts "Downloading #{file} to #{BIPA_ENV[:TAXONOMY_DIR]}: done"
        end
      end
    end

  end
end
