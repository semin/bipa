# Load prerequisite libraries
require 'fileutils'
require 'zlib'

namespace :bipa do
  namespace :analyze do

    desc "Make Distance Matrix for SCOP interfaces using USR"
    task :distance_matrix => [:environment] do
    end

    desc "Create a repository for a selected set of domain sequences"
    task :domain_repos => [:environment] do
      FileUtils.rm_rf(BIPA_ENV[:DOMAIN_DIR]) if File.exists?(BIPA_ENV[:DOMAIN_DIR])
      FileUtils.mkdir_p(BIPA_ENV[:DOMAIN_DIR])
    end

    desc "Make SCOP sequence fasta file for NR construction"
    task :domain => [:environment, :domain_repos] do
      structures = Structure.find(:all)
      structures.each_with_index do |s, i|

        # Resolution filter
        unless (s.resolution > 0 && s.resolution < 3.0)
          puts "!!! Skip '#{s.pdb_code}' (#{i + 1}/#{structures.size})"
          next
        end

        # SCOP domain presence/absence filter
        unless (s.models[0].domains.size > 0)
          puts "!!! Skip '#{s.pdb_code}' (#{i + 2}/#{structures.size})"
          next
        end

        # N.A. residue size filter
        unless (s.models[0].na_residues.size > 4)
          puts "!!! Skip '#{s.pdb_code}' (#{i + 1}/#{structures.size})"
          next
        end

        # Extract SCOP domain sequences and make fasta file for each superfamily level
        puts ">>> Processing... '#{s.pdb_code}' (#{i + 1}/#{structures.size})"

        s.models[0].domains.each do |d|

          # Interface delta ASA filter
          if (d.has_interface_residues?)
            sf        = d.parent.parent.parent.parent
            file      = File.new(File.join(BIPA_ENV[:DOMAIN_DIR], "#{sf[:sunid]}.fa"), 'a')

            header    = ">#{d[:sunid]}\t#{d[:description]}\n"
            sequence  = "#{d.residues.map {|r| r.one_letter_code}}"
            fasta     = header + sequence

            file.puts fasta
            file.close
          end
        end
      end
    end


    desc "Clean CD-HIT results from nrscop repository"
    task :cdhit_repos => [:environment] do
      FileUtils.rm_rf(BIPA_ENV[:CDHIT_DIR]) if File.exists?(BIPA_ENV[:CDHIT_DIR])
      FileUtils.mkdir_p(BIPA_ENV[:CDHIT_DIR])
    end


    desc "Make NR for each SCOP superfamily fasta files"
    task :cdhit => [:environment, :cdhit_repos] do
      fasta_files = Dir.glob(File.join(BIPA_ENV[:DOMAIN_DIR], '*.fa'))
      fasta_files.each do |ff|
        sunid = File.basename(ff, '.fa')
        output_file = File.join(BIPA_ENV[:CDHIT_DIR], "#{sunid}_nr#{(BIPA_ENV[:CDHIT_CUTOFF] * 100).to_i}.fa")
        system "#{BIPA_ENV[:CDHIT_BIN]} -i #{ff} -o #{output_file} -c #{BIPA_ENV[:CDHIT_CUTOFF]} -n #{BIPA_ENV[:CDHIT_WORD]}"
        #system "#{BIPA_ENV[:PSICDHIT_BIN]} -i #{ff} -o #{output_file} -c #{BIPA_ENV[:CDHIT_CUTOFF]}"
      end
    end


    desc "Create a repository for statistical analysis"
    task :stats_repos => [:environment] do
      FileUtils.rm_rf(BIPA_ENV[:STATS_DIR]) if File.exists?(BIPA_ENV[:STATS_DIR])
      FileUtils.mkdir_p(BIPA_ENV[:STATS_DIR])
    end


    desc "Conduct statistical analysis"
    task :stats => [:environment, :stats_repos] do
      include Bipa::Constants

      cnt       = 0
      dna_rows  = []
      rna_rows  = []

      header =  "Type\t" +
                "Fold\t" +
                "Superfamily\t" +
                "PDB code\t" +
                "SunID\t" +
                "Domain\t" +
                "Domain descripton\t" +
                "Resolution\t" +
                "Species\t" +
                "Delta ASA\t" +
                "H-bonds\t" +
                "Water mediated H-bonds\t" +
                "van der Waals contacts\t" +
                "Polarity\t"

      header += AminoAcids::STANDARD.join("\t")
      header += "\t"
      header += DSSP::SSE.join("\t")
      header += "\t"

      frequency_header = []
      AminoAcids::STANDARD.each do |aa|
        # Just use RNA bases here then fix it for DNA in Excel!
        NucleicAcids::RNA.each do |na|
          frequency_header << "#{aa}<->#{na}"
        end
        frequency_header << "#{aa}<->Sugar"
        frequency_header << "#{aa}<->Phosphate"
      end

      header += (frequency_header * 3).join("\t")
      header += "\n\n"

      #puts header
      stats_file = File.new(File.join(BIPA_ENV[:STATS_DIR], BIPA_ENV[:STATS_FILE]), 'w')
      stats_file.puts header
      stats_file.close

      fm = ForkManager.new(BIPA_ENV[:MAX_FORK])

      fm.manage do

        fasta_files = Dir.glob(File.join(BIPA_ENV[:CDHIT_DIR], '*.fa'))
        fasta_files.each do |fasta_file|

          fm.fork do

            sf_sunid      = $1 if File.basename(fasta_file, '.fa') =~ /^(\d+)/
            sf_stats_file = File.new(File.join(BIPA_ENV[:STATS_DIR], "#{sf_sunid}.tmp"), 'w')
            superfamily   = Scop.find_by_sunid(sf_sunid)
            fold          = superfamily.parent

            IO.foreach(fasta_file) do |line|
              if (line =~ /^>(\d+)/)
                cnt += 1
                px_sunid    = $1.to_i
                domain      = Scop.find_by_sunid(px_sunid)
                na_tag      = if domain.model.has_dna_residues?
                                'DNA'
                              else
                                'RNA'
                              end

                species     = domain.parent
                pdomain     = species.parent
                delta_asa   = domain.delta_asa
                structure   = domain.model.structure
                hbond_num   = domain.hbonds.size
                whbond_num  = domain.whbonds.size
                contact_num = domain.contacts.size - hbond_num

                aa_propensities   = AminoAcids::STANDARD.map {|aa| domain.propensity_of_aa(aa)}
                sse_propensities  = DSSP::SSE.map {|sse| domain.propensity_of_sse(sse)}

                hbond_frequencies = []
                AminoAcids::STANDARD.each do |aa|
                  if na_tag == 'DNA'
                    NucleicAcids::DNA.each do |na|
                      hbond_frequencies << domain.frequency_of_hbonds(aa, na)
                    end
                    hbond_frequencies << domain.frequency_of_hbonds(aa, 'sugar')
                    hbond_frequencies << domain.frequency_of_hbonds(aa, 'phosphate')
                  else
                    NucleicAcids::RNA.each do |na|
                      hbond_frequencies << domain.frequency_of_hbonds(aa, na)
                    end
                    hbond_frequencies << domain.frequency_of_hbonds(aa, 'sugar')
                    hbond_frequencies << domain.frequency_of_hbonds(aa, 'phosphate')
                  end
                end

                whbond_frequencies = []
                AminoAcids::STANDARD.each do |aa|
                  if na_tag == 'DNA'
                    NucleicAcids::DNA.each do |na|
                      whbond_frequencies << domain.frequency_of_whbonds(aa, na)
                    end
                    whbond_frequencies << domain.frequency_of_whbonds(aa, 'sugar')
                    whbond_frequencies << domain.frequency_of_whbonds(aa, 'phosphate')
                  else
                    NucleicAcids::RNA.each do |na|
                      whbond_frequencies << domain.frequency_of_whbonds(aa, na)
                    end
                    whbond_frequencies << domain.frequency_of_whbonds(aa, 'sugar')
                    whbond_frequencies << domain.frequency_of_whbonds(aa, 'phosphate')
                  end
                end

                contact_frequencies = []
                AminoAcids::STANDARD.each do |aa|
                  if na_tag == 'DNA'
                    NucleicAcids::DNA.each do |na|
                      contact_frequencies << domain.frequency_of_contacts(aa, na)
                    end
                    contact_frequencies << domain.frequency_of_contacts(aa, 'sugar')
                    contact_frequencies << domain.frequency_of_contacts(aa, 'phosphate')
                  else
                    NucleicAcids::RNA.each do |na|
                      contact_frequencies << domain.frequency_of_contacts(aa, na)
                    end
                    contact_frequencies << domain.frequency_of_contacts(aa, 'sugar')
                    contact_frequencies << domain.frequency_of_contacts(aa, 'phosphate')
                  end
                end

                row = "#{na_tag}\t" +
                      "#{fold[:description]}\t" +
                      "#{superfamily[:description]}\t" +
                      "#{domain[:pdb_code]}\t" +
                      "#{domain[:sunid]}\t" +
                      "#{domain[:description].gsub(/^\S{4}\s+/,'')}\t" +
                      "#{pdomain[:description]}\t" +
                      "#{structure[:resolution]}\t" +
                      "#{species[:description].gsub(/\[.*\]/,'')}\t" +
                      "#{delta_asa}\t" +
                      "#{hbond_num}\t" +
                      "#{whbond_num}\t" +
                      "#{contact_num}\t" +
                      "#{domain.interface_polarity}\t"

                row += aa_propensities.join("\t")
                row += "\t"
                row += sse_propensities.join("\t")
                row += "\t"
                row += hbond_frequencies.join("\t")
                row += "\t"
                row += whbond_frequencies.join("\t")
                row += "\t"
                row += contact_frequencies.join("\t")

                #puts row
                sf_stats_file.puts row
              end # if
            end # IO.foreach(fasta_file)
            sf_stats_file.close
          end # fm.fork
        end # fasta_files.each
      end # fm.manage
      system("cat #{File.join(BIPA_ENV[:STATS_DIR], '*.tmp')} >> #{File.join(BIPA_ENV[:STATS_DIR], BIPA_ENV[:STATS_FILE])}")
    end # task

  end
end
