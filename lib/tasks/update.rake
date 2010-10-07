namespace :update do
  namespace :bipa do

    # this is a disposable task
    desc "Update 'reg_{dna/rna}' columns of 'chain' and 'structures' table"
    task :reg_cols => [:environment] do

      %w[dna rna].each do |na|
        klass = "Chain#{na.capitalize}Interface".constantize
        klass.find_each do |chain_interface|
          # update chain's reg_[d/r]na column
          chain     = chain_interface.chain
          chain.send("reg_#{na}=", true);
          chain.save!

          #update structure's reg_[d/r]na column
          structure = chain.model.structure
          structure.send("reg_#{na}=", true);
          structure.save!

          $logger.debug "#{structure.pdb_code}_#{chain.chain_code} has a #{na.upcase} interface"
        end
      end
    end

    desc "Update 'rep_{dna/rna}' columns of 'scops' table"
    task :subfamily_representatives => [:environment] do

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do
        sub_fams  = Subfamily.all
        conn      = ActiveRecord::Base.remove_connection

        sub_fams.each_with_index do |sub_fam, i|
          fm.fork do
            ActiveRecord::Base.establish_connection(conn)
            rep   = sub_fam.calculate_representative
            na    = sub_fam.class.to_s.match(/dna/i) ? "dna" : "rna"
            cnt   = "(#{i+1}/#{sub_fams.size})"
            sub_fam_name  = "#{sub_fam.class}, #{sub_fam.id}"

            unless rep.nil?
              rep.send("rep_#{na}=", true)
              rep.save!

              if rep.is_a? Scop
                rep.ancestors.each do |anc|
                  anc.send("rep_#{na}=", true)
                  anc.save!
                end
              end

              rep_name = rep.is_a?(Chain) ? rep.fasta_header : rep.sid
              $logger.info "Updating representative structure, #{rep_name} for #{sub_fam_name} #{cnt}: done"
            else
              $logger.warn "No representative structure for #{sub_fam_name} #{cnt}"
            end

            ActiveRecord::Base.remove_connection
          end
        end
        ActiveRecord::Base.establish_connection(conn)
      end
    end


    desc "Update atoms' and residues' DNA/RNA interaction counts"
    task :interaction_counts => [:environment] do

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do
        tot = AaResidue.count
        idx = 0

        AaResidue.find_in_batches do |grp|
          idx   += 1
          ids   = grp.map(&:id)
          conn  = ActiveRecord::Base.remove_connection

          fm.fork do
            ActiveRecord::Base.establish_connection(conn)

            ids.each do |id|
              aar = AaResidue.find(id)
              %w[dna rna].each do |na|
                aar.atoms.each do |atm|
                  atm.send("hbonds_#{na}_as_donor_count=",
                           atm.hbonds_as_donor.select { |b| b.acceptor.send("#{na}?") }.size)
                  atm.send("hbonds_#{na}_as_acceptor_count=",
                           atm.hbonds_as_acceptor.select { |b| b.donor.send("#{na}?") }.size)
                  atm.send("whbonds_#{na}_count=",
                           atm.whbonds.select { |b| b.whbonding_atom.send("#{na}?") }.size)
                  atm.send("vdw_contacts_#{na}_count=",
                           atm.vdw_contacts.select { |b| b.vdw_contacting_atom.send("#{na}?") }.size)
                  atm.save!
                end
                aar.send("hbonds_#{na}_as_donor_count=",
                         aar.atoms.sum(:"hbonds_#{na}_as_donor_count"))
                aar.send("hbonds_#{na}_as_acceptor_count=",
                         aar.atoms.sum(:"hbonds_#{na}_as_acceptor_count"))
                aar.send("whbonds_#{na}_count=",
                         aar.atoms.sum(:"whbonds_#{na}_count"))
                aar.send("vdw_contacts_#{na}_count=",
                         aar.atoms.sum(:"vdw_contacts_#{na}_count"))
                aar.save!
              end
            end
            $logger.info "Updating interaction counts for group #{idx} of #{grp.size} residues (out of #{tot}): done"
            ActiveRecord::Base.remove_connection
          end
          ActiveRecord::Base.establish_connection(conn)
        end
      end
    end


    desc "Update ASA related fields for 'residues' table"
    task :residues_asa_columns => [:environment] do

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do
        pdbs = Structure.all.map(&:pdb_code)
        conn = ActiveRecord::Base.remove_connection

        pdbs.each_with_index do |pdb, i|
          fm.fork do
            ActiveRecord::Base.establish_connection(conn)
            s = Structure.find_by_pdb_code(pdb)
            s.models.first.std_residues.each do |r|
              %w[unbound bound delta].each do |state|
                r.send("#{state}_asa=", r.send("calculate_#{state}_asa"))
                r.save!
              end
            end
            $logger.info "Updating ASA columns of residues table for #{pdb} (#{i+1}/#{pdbs.size}): done"
            ActiveRecord::Base.remove_connection
          end
        end
        ActiveRecord::Base.establish_connection(conn)
      end
    end


    desc "Update auxiliary fields for interfaces table"
    task :interfaces_auxiliary_columns => [:environment] do

      include Bipa::Constants

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do
        interfaces  = ProteinNucleicAcidInterface.all
        conn        = ActiveRecord::Base.remove_connection

        interfaces.each_with_index do |interface, i|
          fm.fork do
            ActiveRecord::Base.establish_connection(conn)

            interface.update_attribute :asa,                      interface.calculate_asa
            interface.update_attribute :asa_percentage,           interface.calculate_asa_percentage
            interface.update_attribute :polarity,                 interface.calculate_polarity
            interface.update_attribute :atoms_count,              interface.atoms.length
            interface.update_attribute :residues_count,           interface.residues.length
            interface.update_attribute :vdw_contacts_count,       interface.vdw_contacts.length
            interface.update_attribute :whbonds_count,            interface.whbonds.length
            interface.update_attribute :hbonds_as_donor_count,    interface.hbonds_as_donor.length
            interface.update_attribute :hbonds_as_acceptor_count, interface.hbonds_as_acceptor.length
            interface.update_attribute :hbonds_count,             interface.hbonds_as_donor.length + interface.hbonds_as_acceptor.length

            AminoAcids::Residues::STANDARD.each do |aa|
              interface.update_attribute :"residue_asa_propensity_of_#{aa.downcase}", interface.calculate_residue_asa_propensity_of(aa)
              interface.update_attribute :"residue_asa_percentage_of_#{aa.downcase}", interface.calculate_residue_asa_percentage_of(aa)
              interface.update_attribute :"residue_cnt_propensity_of_#{aa.downcase}", interface.calculate_residue_cnt_propensity_of(aa)
              interface.update_attribute :"residue_cnt_percentage_of_#{aa.downcase}", interface.calculate_residue_cnt_percentage_of(aa)
            end

            Sses::ALL.each do |sse|
              interface.update_attribute :"sse_asa_propensity_of_#{sse.downcase}", interface.calculate_sse_asa_propensity_of(sse)
              interface.update_attribute :"sse_asa_propensity_of_#{sse.downcase}", interface.calculate_sse_asa_propensity_of(sse)
              interface.update_attribute :"sse_cnt_percentage_of_#{sse.downcase}", interface.calculate_sse_cnt_percentage_of(sse)
              interface.update_attribute :"sse_cnt_percentage_of_#{sse.downcase}", interface.calculate_sse_cnt_percentage_of(sse)
            end

            %w[hbond whbond vdw_contact].each do |intact|
              AminoAcids::Residues::STANDARD.each do |aa|
                interface.send("frequency_of_#{intact}_between_#{aa.downcase}_and_nucleic_acids=",
                                interface.send("calculate_frequency_of_#{intact}_between_nucleic_acids_and_", aa))
              end

              nas = "NucleicAcids::#{interface.interface_to.capitalize}::Residues::STANDARD".constantize
              nas.each do |na_residue|
                interface.send("frequency_of_#{intact}_between_amino_acids_and_#{na_residue.downcase}=",
                                interface.send("calculate_frequency_of_#{intact}_between_amino_acids_and_", na_residue))

                AminoAcids::Residues::STANDARD.each do |aa|
                  interface.send("frequency_of_#{intact}_between_#{aa.downcase}_and_#{na_residue.downcase}=",
                                  interface.send("calculate_frequency_of_#{intact}_between", aa, na_residue))
                end
              end

              %w[sugar phosphate].each do |moiety|
                interface.send("frequency_of_#{intact}_between_amino_acids_and_#{moiety}=",
                                AminoAcids::Residues::STANDARD.inject(0) { |sum, aa|
                                sum + interface.send("calculate_frequency_of_#{intact}_between_#{moiety}_and_", aa) })

                AminoAcids::Residues::STANDARD.each do |aa|
                  interface.send("frequency_of_#{intact}_between_#{aa.downcase}_and_#{moiety}=",
                                  interface.send("calculate_frequency_of_#{intact}_between_#{moiety}_and_", aa))
                end
              end
            end
            interface.save!
            $logger.info "Updating auxiliary columns for #{interface.class}, #{interface.id} (#{i+1}/#{interfaces.size}): done"
            ActiveRecord::Base.remove_connection
          end
        end
        ActiveRecord::Base.establish_connection(conn)
      end
    end


    desc "Update JOY templates for SCOP representative alignments"
    task :scop_rep_joytems => [:environment] do

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do
        %w[dna rna].each do |na|
          conn      = ActiveRecord::Base.remove_connection
          fam_dirs  = Pathname.glob(configatron.family_dir.join("scop", "rep", na, "*").to_s)

          fam_dirs.each do |fam_dir|
            fm.fork do
              ActiveRecord::Base.establish_connection(conn)

              tems = Pathname.glob(fam_dir.join("modsalign.tem").to_s)

              if tems.empty?
                $logger.warn "!!! Cannot find JOY template file(s) in #{fam_dir}"
                ActiveRecord::Base.remove_connection
                next
              end

              tems.each do |tem|
                stem    = File.basename(tem, ".tem")
                newtem  = File.join(fam_dir, "#{na}#{stem}.tem")
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
                        $logger.warn  "!!! Unmatched residue at #{di} in #{dom.sid} in #{fam_dir}: " +
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
              $logger.info ">>> Updating JOY template(s) in #{fam_dir}: done"
              ActiveRecord::Base.remove_connection
            end
          end
          ActiveRecord::Base.establish_connection(conn)
        end
      end
    end


    desc "Update JOY templates for representative alignments"
    task :sub_joytems => [:environment] do

      fm = ForkManager.new(configatron.max_fork)
      fm.manage do
        %w[dna rna].each do |na|
          conn        = ActiveRecord::Base.remove_connection
          subfam_dirs = Pathname.glob(configatron.family_dir.join("scop", "sub", na, "*", "*").to_s)

          subfam_dirs.each do |subfam_dir|
            fm.fork do
              ActiveRecord::Base.establish_connection(conn)
              tems = Pathname.glob(subfam_dir.join("msa.tem").to_s)

              if tems.empty?
                $logger.warn "Cannot find JOY template file(s) in #{subfam_dir}"
                ActiveRecord::Base.remove_connection
                next
              end

              tems.each do |tem|
                stem    = tem.basename(".tem")
                newtem  = subfam_dir + "#{na}_#{stem}.tem"
                cp tem, newtem

                bio = Bio::FlatFile.auto(tem)
                bio.each_entry do |entry|
                  if entry.seq_type == "P1" and entry.definition == "sequence"
                    dom = ScopDomain.find_by_sunid(entry.entry_id)

                    if dom.nil?
                      $logger.warn "Cannot find #{entry.entry_id} of #{tem} from BIPA"
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
                        $logger.warn  "Mismatch at #{di}, in #{dom.sid}, #{dom.sunid} " +
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
                        $logger.warn  "Unmatched residue at #{di} in #{dom.sid} in #{subfam_dir}: " +
                                      "BIPA: #{dbrs[di].one_letter_code} <=> TEM: #{res}"
                      end
                    end

                    newtem.open("a") do |file|
                      file.puts ">P1;#{entry.entry_id}"
                      file.puts "#{na.upcase} interface"
                      file.puts bind.join + "*"

                      file.puts ">P1;#{entry.entry_id}"
                      file.puts "hydrogen bond to #{na.upcase}"
                      file.puts hbond.join + "*"

                      file.puts ">P1;#{entry.entry_id}"
                      file.puts "water-mediated hydrogen bond to #{na.upcase}"
                      file.puts whbond.join + "*"

                      file.puts ">P1;#{entry.entry_id}"
                      file.puts "van der Waals contact to #{na.upcase}"
                      file.puts vdw.join + "*"

                      file.puts ">P1;#{entry.entry_id}"
                      file.puts "#{na.upcase}-binding type"
                      file.puts nabind.join + "*"
                    end
                  end
                end
              end

              $logger.info "Updating JOY template(s) in #{subfam_dir}: done"
              ActiveRecord::Base.remove_connection
            end
          end
          ActiveRecord::Base.establish_connection(conn)
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
