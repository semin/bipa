namespace :bipa do
  namespace :update do

    desc "Update 'rep_{dna/rna}' columns of 'scop' table"
    task :scoprep => [:environment] do

      %w[dna rna].each do |na|
        klass = "#{na.capitalize}BindingSubfamily".constantize
        klass.all.each do |subfam|
          rep = subfam.representative
          unless rep.nil?
            rep.send("rep_#{na}=", true)
            rep.save!
            rep.ancestors.each do |anc|
              anc.send("rep_#{na}=", true)
              anc.save!
            end
            $logger.info ">>> Updating representative structure, #{rep.id} for #{klass}, #{subfam.id}: done"
          else
            $logger.warn "!!! No representative structure for #{klass}, #{subfam.id}"
          end
        end
      end
    end


    desc "Update atoms' and residues' DNA/RNA interaction counts"
    task :intcnts => [:environment] do

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do
        AaResidue.find_in_batches do |grp|
          ids   = grp.map(&:id)
          conf  = ActiveRecord::Base.remove_connection

          fm.fork do
            ActiveRecord::Base.establish_connection(conf)

            ids.each do |id|
              aar = AaResidue.find(id)
              %w[dna rna].each do |na|
                aar.atoms.each do |atm|
                  atm.send("hbonds_#{na}_as_donor_count=",    atm.hbonds_as_donor.select { |b| b.acceptor.send("#{na}?") }.size)
                  atm.send("hbonds_#{na}_as_acceptor_count=", atm.hbonds_as_acceptor.select { |b| b.donor.send("#{na}?") }.size)
                  atm.send("whbonds_#{na}_count=",            atm.whbonds.select { |b| b.whbonding_atom.send("#{na}?") }.size)
                  atm.send("vdw_contacts_#{na}_count=",       atm.vdw_contacts.select { |b| b.vdw_contacting_atom.send("#{na}?") }.size)
                  atm.save!
                end
    #            aar.send("hbonds_#{na}_as_donor_count=",    aar.atoms.sum(:"hbonds_#{na}_as_donor_count"))
    #            aar.send("hbonds_#{na}_as_acceptor_count=", aar.atoms.sum(:"hbonds_#{na}_as_acceptor_count"))
    #            aar.send("whbonds_#{na}_count=",            aar.atoms.sum(:"whbonds_#{na}_count"))
    #            aar.send("vdw_contacts_#{na}_count=",       aar.atoms.sum(:"vdw_contacts_#{na}_count"))
    #            aar.save!
              end

            end
            $logger.info ">>> Updating atomic interaction counts for #{grp.size} residues: done"
            ActiveRecord::Base.remove_connection
          end
          ActiveRecord::Base.establish_connection(conf)
        end
      end
    end


    desc "Update ASA related fields for 'residues' table"
    task :resasa => [:environment] do

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do
        pdbs = Structure.all.map(&:pdb_code)
        conf = ActiveRecord::Base.remove_connection

        pdbs.each do |pdb|
          fm.fork do
            ActiveRecord::Base.establish_connection(conf)

            s = Structure.find_by_pdb_code(pdb)
            s.models.first.std_residues.each do |r|
              %w[unbound bound delta].each do |state|
                r.send("#{state}_asa=", r.send("calculate_#{state}_asa"))
                r.save!
              end
            end
            $logger.info ">>> Updating residue ASA fields for #{pdb_code}: done"
            ActiveRecord::Base.remove_connection
          end
        end
        ActiveRecord::Base.establish_connection(conf)
      end
    end


    desc "Update secondary fields for interfaces table"
    task :intsec => [:environment] do

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do
        %w[dna rna].each do |na|
          nas   = "Bipa::Constants::NucleicAcids::#{na.capitalize}::Residues::STANDARD".constantize
          ids   = "Domain#{na.capitalize}Interface".constantize.all.map(&:id)
          conf  = ActiveRecord::Base.remove_connection

          ids.each do |id|
            fm.fork do
              ActiveRecord::Base.establish_connection(conf)

              int = DomainInterface.find(id)
              int.update_attribute :asa,                      int.calculate_asa
              int.update_attribute :percent_asa,              int.calculate_percent_asa
              int.update_attribute :polarity,                 int.calculate_polarity
              int.update_attribute :atoms_count,              int.atoms.length
              int.update_attribute :residues_count,           int.residues.length
              int.update_attribute :vdw_contacts_count,       int.vdw_contacts.length
              int.update_attribute :whbonds_count,            int.whbonds.length
              int.update_attribute :hbonds_as_donor_count,    int.hbonds_as_donor.length
              int.update_attribute :hbonds_as_acceptor_count, int.hbonds_as_acceptor.length
              int.update_attribute :hbonds_count,             int.hbonds_as_donor.length + int.hbonds_as_acceptor.length

              AminoAcids::Residues::STANDARD.each do |aa|
                int.update_attribute :"residue_propensity_of_#{aa.downcase}", int.calculate_residue_propensity_of(aa)
                int.update_attribute :"residue_percentage_of_#{aa.downcase}", int.calculate_residue_percentage_of(aa)
              end
              Sses::ALL.each do |sse|
                int.update_attribute :"sse_propensity_of_#{sse.downcase}", int.calculate_sse_propensity_of(sse)
                int.update_attribute :"sse_percentage_of_#{sse.downcase}", int.calculate_sse_percentage_of(sse)
              end
              %w[hbond whbond vdw_contact].each do |intact|
                AminoAcids::Residues::STANDARD.each do |aa|
                  int.send("frequency_of_#{intact}_between_#{aa.downcase}_and_nucleic_acids=",
                                int.send("calculate_frequency_of_#{intact}_between_nucleic_acids_and_", aa))
                end

                nas.each do |na_residue|
                  int.send("frequency_of_#{intact}_between_amino_acids_and_#{na_residue.downcase}=",
                                int.send("calculate_frequency_of_#{intact}_between_amino_acids_and_", na_residue))

                  AminoAcids::Residues::STANDARD.each do |aa|
                    int.send("frequency_of_#{intact}_between_#{aa.downcase}_and_#{na_residue.downcase}=",
                                  int.send("calculate_frequency_of_#{intact}_between", aa, na_residue))
                  end
                end

                %w[sugar phosphate].each do |moiety|
                  int.send("frequency_of_#{intact}_between_amino_acids_and_#{moiety}=",
                    AminoAcids::Residues::STANDARD.inject(0) { |sum, aa| sum + int.send("calculate_frequency_of_#{intact}_between_#{moiety}_and_", aa) })

                  AminoAcids::Residues::STANDARD.each do |aa|
                    int.send("frequency_of_#{intact}_between_#{aa.downcase}_and_#{moiety}=",
                                  int.send("calculate_frequency_of_#{intact}_between_#{moiety}_and_", aa))
                  end
                end
              end

              int.save!
              $logger.info ">>> Updating secondary fields for #{int.class}, #{int.id}: done"
              ActiveRecord::Base.remove_connection
            end
          end
          ActiveRecord::Base.establish_connection(conf)
        end
      end
    end


    desc "Update JOY templates for alignments"
    task :joytems => [:environment] do

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do
        %w[dna rna].each do |na|
          conf  = ActiveRecord::Base.remove_connection
          fams  = Dir[configatron.family_dir.join("rep", na, "*").to_s]
          subs  = Dir[configatron.family_dir.join("sub", na, "*", "*").to_s]
          dirs  = fams + subs

          dirs.each do |dir|
            fm.fork do
              ActiveRecord::Base.establish_connection(conf)

              tems = Dir[File.join(dir, "modsalign*.tem").to_s]

              if tems.empty?
                $logger.warn "!!! Cannot find JOY template file(s) in #{dir}"
                ActiveRecord::Base.remove_connection
                next
              end

              tems.each do |tem|
                stem    = File.basename(tem, ".tem")
                newtem  = File.join(dir, "#{na}#{stem}.tem")
                cp tem, newtem

                bio = Bio::FlatFile.auto(tem)
                bio.each_entry do |entry|
                  if entry.seq_type == "P1" and entry.definition == "sequence"
                    dom = ScopDomain.find_by_sunid(entry.entry_id)

                    if dom.nil?
                      $logger.warn "!!! Cannot find #{entry.entry_id} of #{tem} from BIPA"
                      next
                    end

                    bind, hbond, whbond, vdw, nabind = [], [], [], [], []
                    dbrs = dom.aa_residues
                    ffrs = entry.seq.split("")

                    di = 0

                    ffrs.each_with_index do |res, fi|

                      if fi != 0 and fi % 75 == 0
                        bind << "\n"; hbond << "\n"; whbond << "\n"; vdw << "\n"; nabind << "\n"
                      end

                      if res == "-"
                        bind << "-"; hbond << "-"; whbond << "-"; vdw << "-"; nabind << "-"
                      elsif dbrs[di].nil?
                        bind << "F"; hbond << "F"; whbond << "F"; vdw << "F"; nabind << "N"
                        $logger.warn  "!!! Mismatch at #{di}, in #{dom.sid}, #{dom.sunid} " +
                                    "(TEM: #{res} <=> BIPA: None)."
                      elsif dbrs[di].one_letter_code == res
                        dbrs[di].send("binding_#{na}?")         ? bind    << "T" : bind   << "F"
                        dbrs[di].send("hbonding_#{na}?")        ? hbond   << "T" : hbond  << "F"
                        dbrs[di].send("whbonding_#{na}?")       ? whbond  << "T" : whbond << "F"
                        dbrs[di].send("vdw_contacting_#{na}?")  ? vdw     << "T" : vdw    << "F"
                        if hbond.last == "T"
                          nabind << "H"
                        elsif whbond.last == "T"
                          nabind << "W"
                        elsif vdw.last == "T"
                          nabind << "V"
                        else
                          nabind << "N"
                        end
                        di += 1
                      else
                        bind << "F"; hbond << "F"; whbond << "F"; vdw << "F"; nabind << "N"
                        $logger.warn  "!!! Unmatched residue at #{di} in #{dom.sid} in #{dir}: " +
                                      "BIPA: #{dbrs[di].one_letter_code} <=> TEM: #{res}"
                      end
                    end

                    File.open(newtem, "a") do |f|
                      f.puts ">P1;#{entry.entry_id}"
                      f.puts "#{na.upcase} interface"
                      f.puts bind.join + "*"

                      f.puts ">P1;#{entry.entry_id}"
                      f.puts "hydrogen bond to #{na.upcase}"
                      f.puts hbond.join + "*"

                      f.puts ">P1;#{entry.entry_id}"
                      f.puts "water-mediated hydrogen bond to #{na.upcase}"
                      f.puts whbond.join + "*"

                      f.puts ">P1;#{entry.entry_id}"
                      f.puts "van der Waals contact to #{na.upcase}"
                      f.puts vdw.join + "*"

                      f.puts ">P1;#{entry.entry_id}"
                      f.puts "#{na.upcase}-binding type"
                      f.puts nabind.join + "*"
                    end
                  end
                end
              end
              $logger.info ">>> Updating JOY template(s) in #{dir}: done"
              ActiveRecord::Base.remove_connection
            end
          end
          ActiveRecord::Base.establish_connection(conf)
        end
      end
    end


    desc "Filter 'vdw_contacts' table not to contain any hbonds or whbonds"
    task :filter_vdw_contacts => [:environment] do
      i = 0
      Hbond.find_each do |hbond|
        vdw_contact1 = VdwContact.find_by_atom_id_and_vdw_contacting_atom_id(hbond.donor, hbond.acceptor)
        vdw_contact2 = VdwContact.find_by_atom_id_and_vdw_contacting_atom_id(hbond.acceptor, hbond.donor)
        if vdw_contact1
          VdwContact.destroy(vdw_contact1)
          $logger.info ">>> Destroyed vdw contact, #{vdw_contact1.id} (#{i += 1})"
        end
        if vdw_contact2
          VdwContact.destroy(vdw_contact2)
          $logger.info ">>> Destroyed vdw contact, #{vdw_contact2.id} (#{i += 1})"
        end
      end
    end


    desc "Update interface_distances table"
    task :interface_similarities => [:environment] do

      include Bipa::Constants

      interfaces = DomainInterface.find(:all,
                                        :select => "id, asa, polarity, " +
                                            AminoAcids::Residues::STANDARD.map { |a| "residue_propensity_of_#{a.downcase}" }.join(",") + "," +
                                            Sses::ALL.map { |s| "sse_propensity_of_#{s.downcase}" }.join(","))
      total      = (interfaces.count ** 2 - interfaces.count) / 2
      fmanager   = ForkManager.new(configatron.max_fork)

      fmanager.manage do
        0.upto(interfaces.count - 2) do |i|
          (i + 1).upto(interfaces.count - 1) do |j|
            index = j + (interfaces.count * i) - (1..i+1).inject { |s,e| s + e }
            if InterfaceSimilarity.find_by_interface_id_and_similar_interface_id(interfaces[i].id, interfaces[j].id)
              #$logger.info ">>> Skipped interface distances between interface #{interfaces[i].id} and #{interfaces[j].id}: done (#{index}/#{total})"
              next
            else
              config = ActiveRecord::Base.remove_connection
              fmanager.fork do
                ActiveRecord::Base.establish_connection(config)
                is                                = InterfaceSimilarity.new
                is.interface                      = interfaces[i]
                is.interface_target               = interfaces[j]
                is.similarity_in_usr              = interfaces[i].shape_similarity_with(interfaces[j]) rescue 0.0
                is.similarity_in_asa              = (interfaces[i][:asa] - interfaces[j][:asa]).abs.to_similarity
                is.similarity_in_polarity         = (interfaces[i][:polarity] - interfaces[j][:polarity]).abs.to_similarity
                is.similarity_in_res_composition  = NMath::sqrt((interfaces[i].residue_propensity_vector - interfaces[j].residue_propensity_vector)**2).to_similarity
                is.similarity_in_sse_composition  = NMath::sqrt((interfaces[i].sse_propensity_vector - interfaces[j].sse_propensity_vector)**2).to_similarity
                is.similarity_in_all              = [is.similarity_in_usr, is.similarity_in_asa, is.similarity_in_polarity, is.similarity_in_res_composition, is.similarity_in_sse_composition].to_stats_array.mean
                is.save!

                $logger.info ">>> Updating interface distances between interface #{interfaces[i].id} and #{interfaces[j].id}: done (#{index}/#{total})"
                ActiveRecord::Base.remove_connection
              end
              ActiveRecord::Base.establish_connection(config)
            end
          end
        end
      end # fmanager.manage
    end


    desc "Update cssed_sequence for all sequences"
    task :seqcss => [:environment] do

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do
        ids   = Sequence.all.map(&:id)
        conf  = ActiveRecord::Base.remove_connection

        ids.each do |id|
          fm.fork do
            ActiveRecord::Base.establish_connection(conf)

            seq = Sequence.find(id)

            unless seq.cssed_sequence.nil?
              $logger.info ">>> Skipped Sequence, #{seq.id}"
              ActiveRecord::Base.remove_connection
              next
            end

            seq.cssed_sequence = seq.formatted_sequence
            seq.save!
            $logger.info ">>> Updating cssed_sequence of Sequence, #{seq.id}: done"
            ActiveRecord::Base.remove_connection
          end
        end
        ActiveRecord::Base.establish_connection(conf)
      end
    end


    desc "Update cssed_sequence for all chains"
    task :chncss => [:environment] do

      fm  = ForkManager.new(configatron.max_fork)
      ids = AaChain.all.map(&:id)

      fm.manage do
        config = ActiveRecord::Base.remove_connection

        ids.each do |id|
          fm.fork do
            ActiveRecord::Base.establish_connection(config)

            chn = AaChain.find(id)

            unless chn.cssed_sequence.nil?
              $logger.info ">>> Skipped Chain, #{chn.id}"
              ActiveRecord::Base.remove_connection
              next
            end

            chn.cssed_sequence = chn.formatted_sequence
            chn.save!
            $logger.info ">>> Updating cssed_sequence of Chain, #{chn.id}: done"
            ActiveRecord::Base.remove_connection
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end

  end
end
