namespace :bipa do
  namespace :update do

    desc "Update 'vdw_contacts_count' column of 'atoms' table"
    task :atoms_vdw_contacts_count => [:environment] do
      Atom.find_each(:select => "id, vdw_contacts_count", :per_page => 10000) do |atom|
        atom.update_attribute :vdw_contacts_count, atom.vdw_contacts.length
      end
    end


    desc "Update 'whbonds_count' column of 'atoms' table"
    task :atoms_whbonds_count => [:environment] do
      Atom.find_each(:select => "id, whbonds_count", :per_page => 10000) do |atom|
        atom.update_attribute :whbonds_count, atom.whbonds.length
      end
    end


    desc "Update 'hbonds_as_donor_count' column of 'atoms' table"
    task :atoms_hbonds_as_donor_count => [:environment] do
      Atom.find_each(:select => "id, hbonds_as_donor_count", :per_page => 10000) do |atom|
        atom.update_attribute :hbonds_as_donor_count, atom.hbonds_as_donor.length
      end
    end


    desc "Update 'hbonds_as_acceptor_count' column of 'atoms' table"
    task :atoms_hbonds_as_acceptor_count => [:environment] do
      Atom.find_each(:select => "id, hbonds_as_acceptor_count", :per_page => 10000) do |atom|
        atom.update_attribute :hbonds_as_acceptor_count, atom.hbonds_as_acceptor.length
      end
    end


    desc "Update 'repPID_NA' columns of 'scop' table"
    task :scop_rep => [:environment] do

      %w[dna rna].each do |na|
        configatron.rep_pids.each do |pid|
          klass = "Red#{pid}#{na.capitalize}BindingSubfamily".constantize
          klass.all.each do |subfamily|
            rep = subfamily.representative
            unless rep.nil?
              rep.send("rep#{pid}_#{na}=", true)
              rep.save!
              rep.ancestors.each do |anc|
                anc.send("rep#{pid}_#{na}=", true)
                anc.save!
              end
              $logger.info ">>> Updating representative structure, #{rep.id} for #{klass}, #{subfamily.id} at PID, #{pid}: done"
            else
              $logger.warn "!!! No representative structure for #{klass}, #{subfamily.id} at PID, #{pid}"
            end
          end
        end
      end
    end


    desc "Update atoms' DNA/RNA interaction counts"
    task :atoms_intcounts => [:environment] do
    end


    desc "Update residues' DNA/RNA interaction counts"
    task :residues_intcounts => [:environment] do

      interface_ids = DomainInterface.all.map(&:id)
      fmanager      = ForkManager.new(configatron.max_fork)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection
        interface_ids.each_with_index do |id, i|
          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)
            interface = DomainInterface.find(id)
            %w[dna rna].each do |na|
              interface.residues.each do |aa|
                aa.send("hbonds_#{na}_as_donor_count=",     aa.hbonds_as_donor.select { |b| b.acceptor.send("#{na}?") }.size)
                aa.send("hbonds_#{na}_as_acceptor_count=",  aa.hbonds_as_acceptor.select { |b| b.donor.send("#{na}?") }.size)
                aa.send("whbonds_#{na}_count=",             aa.whbonds.select { |b| b.whbonding_atom.send("#{na}?") }.size)
                aa.send("vdw_contacts_#{na}_count=",        aa.vdw_contacts.select { |b| b.vdw_contacting_atom.send("#{na}?") }.size)
                aa.save!
              end
            end
            ActiveRecord::Base.remove_connection
          end
          $logger.info ">>> Counting atomic interactions for residues of Interface, #{id}: done (#{i+1}/#{interface_ids.size})"
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


    desc "Update ASA related fields for 'residues' table"
    task :residues_asa => [:environment] do

      pdb_codes = Structure.all.map(&:pdb_code).reverse
      fmanager  = ForkManager.new(configatron.max_fork)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection
        pdb_codes.each_with_index do |pdb_code, i|
          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)
            structure = Structure.find_by_pdb_code(pdb_code)
            structure.models.first.std_residues.each do |residue|
              %w[unbound bound delta].each do |state|
                residue.send("#{state}_asa=", residue.send("calculate_#{state}_asa"))
                residue.save!
              end
            end
            $logger.info ">>> Updating Residue ASA fields for #{structure.pdb_code}: done (#{i + 1}/#{pdb_codes.count})"
            ActiveRecord::Base.remove_connection
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end


    desc "Update secondary fields for interfaces table"
    task :interfaces_secondary_fields => [:environment] do

      include Bipa::Constants

      %w[dna rna].each do |na|
        na_residues = (na.match(/dna/i) ? "NucleicAcids::Dna::Residues::STANDARD" : "NucleicAcids::Rna::Residues::STANDARD").constantize
        interfaces  = "Domain#{na.capitalize}Interface".constantize.all
        fmanager    = ForkManager.new(configatron.max_fork)

        fmanager.manage do
          config = ActiveRecord::Base.remove_connection

          interfaces.each_with_index do |interface, i|
            fmanager.fork do
              ActiveRecord::Base.establish_connection(config)

              interface.update_attribute :percent_asa, interface.calculate_percent_asa
              interface.update_attribute :polarity, interface.calculate_polarity
              interface.update_attribute :atoms_count, interface.atoms.length
              interface.update_attribute :residues_count, interface.residues.length
              interface.update_attribute :vdw_contacts_count, interface.vdw_contacts.length
              interface.update_attribute :whbonds_count, interface.whbonds.length
              interface.update_attribute :hbonds_as_donor_count, interface.hbonds_as_donor.length
              interface.update_attribute :hbonds_as_acceptor_count, interface.hbonds_as_acceptor.length
              interface.update_attribute :hbonds_count, interface.hbonds_as_donor.length + interface.hbonds_as_acceptor.length

              AminoAcids::Residues::STANDARD.each do |aa|
                interface.update_attribute :"residue_propensity_of_#{aa.downcase}", interface.calculate_residue_propensity_of(aa)
                interface.update_attribute :"residue_percentage_of_#{aa.downcase}", interface.calculate_residue_percentage_of(aa)
              end
              Sses::ALL.each do |sse|
                interface.update_attribute :"sse_propensity_of_#{sse.downcase}", interface.calculate_sse_propensity_of(sse)
                interface.update_attribute :"sse_percentage_of_#{sse.downcase}", interface.calculate_sse_percentage_of(sse)
              end
              %w[hbond whbond vdw_contact].each do |intact|
                AminoAcids::Residues::STANDARD.each do |aa|
                  interface.send("frequency_of_#{intact}_between_#{aa.downcase}_and_nucleic_acids=",
                                interface.send("calculate_frequency_of_#{intact}_between_nucleic_acids_and_", aa))
                end

                na_residues.each do |na_residue|
                  interface.send("frequency_of_#{intact}_between_amino_acids_and_#{na_residue.downcase}=",
                                interface.send("calculate_frequency_of_#{intact}_between_amino_acids_and_", na_residue))

                  AminoAcids::Residues::STANDARD.each do |aa|
                    interface.send("frequency_of_#{intact}_between_#{aa.downcase}_and_#{na_residue.downcase}=",
                                  interface.send("calculate_frequency_of_#{intact}_between", aa, na_residue))
                  end
                end

                %w[sugar phosphate].each do |moiety|
                  interface.send("frequency_of_#{intact}_between_amino_acids_and_#{moiety}=",
                    AminoAcids::Residues::STANDARD.inject(0) { |sum, aa| sum + interface.send("calculate_frequency_of_#{intact}_between_#{moiety}_and_", aa) })

                  AminoAcids::Residues::STANDARD.each do |aa|
                    interface.send("frequency_of_#{intact}_between_#{aa.downcase}_and_#{moiety}=",
                                  interface.send("calculate_frequency_of_#{intact}_between_#{moiety}_and_", aa))
                  end
                end
              end

              interface.save!
              $logger.info ">>> Updating secondary fields for #{interface.class}, #{interface.id}: done (#{i+1}/#{interfaces.size})"
              ActiveRecord::Base.remove_connection
            end
          end
          ActiveRecord::Base.establish_connection(config)
        end
      end
    end


    desc "Update JOY templates for alignments"
    task :joytems => [:environment] do

      config = ActiveRecord::Base.remove_connection

      %w[dna rna].each do |na|
        fam_dirs    = Dir[configatron.family_dir.join("rep*", na, "*").to_s]
        subfam_dirs = Dir[configatron.family_dir.join("sub", na, "*", "red*", "*").to_s]
        dirs        = fam_dirs + subfam_dirs

        dirs.forkify(configatron.max_fork) do |dir|
          ActiveRecord::Base.establish_connection(config)

          tem_files = Dir[File.join(dir, "salign*_mod.tem").to_s]

          if tem_files.nil? or tem_files.size < 1
            $logger.warn "!!! Cannot find JOY template file(s) in #{dir}"
            ActiveRecord::Base.remove_connection
            next
          end

          tem_files.each do |tem_file|
            basename      = File.basename(tem_file, ".tem")
            new_tem_file  = File.join(dir, "#{basename}_na.tem")
            cp tem_file, new_tem_file

            flat_file = Bio::FlatFile.auto(tem_file)
            flat_file.each_entry do |entry|
              if entry.seq_type == "P1" and entry.definition == "sequence"
                domain = ScopDomain.find_by_sunid(entry.entry_id)

                if domain.nil?
                  $logger.warn "!!! Cannot find #{entry.entry_id} of #{tem_file} from BIPA"
                  next
                end

                bind_tem        = []
                hbond_tem       = []
                whbond_tem      = []
                vdw_contact_tem = []
                na_binding_tem  = []
                db_residues     = domain.aa_residues
                ff_residues     = entry.seq.split("")

                di = 0
                ff_residues.each_with_index do |res, fi|
                  break if fi >= db_residues.size

                  if fi != 0 and fi % 75 == 0
                    bind_tem        << "\n"
                    hbond_tem       << "\n"
                    whbond_tem      << "\n"
                    vdw_contact_tem << "\n"
                    na_binding_tem  << "\n"
                  end

                  if (res == "-")
                    bind_tem        << "-"
                    hbond_tem       << "-"
                    whbond_tem      << "-"
                    vdw_contact_tem << "-"
                    na_binding_tem  << "-"
                  elsif (db_residues[di].one_letter_code == res)
                    db_residues[di].send("binding_#{na}?")         ? bind_tem        << "T" : bind_tem         << "F"
                    db_residues[di].send("hbonding_#{na}?")        ? hbond_tem       << "T" : hbond_tem        << "F"
                    db_residues[di].send("whbonding_#{na}?")       ? whbond_tem      << "T" : whbond_tem       << "F"
                    db_residues[di].send("vdw_contacting_#{na}?")  ? vdw_contact_tem << "T" : vdw_contact_tem  << "F"
                    if hbond_tem.last == "T"
                      na_binding_tem << "H"
                    elsif whbond_tem.last == "T"
                      na_binding_tem << "W"
                    elsif vdw_contact_tem.last == "T"
                      na_binding_tem << "V"
                    else
                      na_binding_tem << "N"
                    end
                    di += 1
                  else
                    bind_tem        << "X"
                    hbond_tem       << "X"
                    whbond_tem      << "X"
                    vdw_contact_tem << "X"
                    na_binding_tem  << "X"
                    $logger.warn  "!!! Unmatched residue at #{di} in #{domain.sid} in #{dir}: " +
                                      "BIPA: #{db_residues[di].one_letter_code} <=> TEM: #{res}"
                  end
                end

                File.open(new_tem_file, "a") do |file|
                  file.puts ">P1;#{entry.entry_id}"
                  file.puts "#{na.upcase} interface"
                  file.puts bind_tem.join + "*"

                  file.puts ">P1;#{entry.entry_id}"
                  file.puts "hydrogen bond to #{na.upcase}"
                  file.puts hbond_tem.join + "*"

                  file.puts ">P1;#{entry.entry_id}"
                  file.puts "water-mediated hydrogen bond to #{na.upcase}"
                  file.puts whbond_tem.join + "*"

                  file.puts ">P1;#{entry.entry_id}"
                  file.puts "van der Waals contact to #{na.upcase}"
                  file.puts vdw_contact_tem.join + "*"

                  file.puts ">P1;#{entry.entry_id}"
                  file.puts "#{na.upcase}-binding type"
                  file.puts na_binding_tem.join + "*"
                end
              end
            end
          end
          $logger.info ">>> Updating JOY template(s) in #{dir}: done"
          ActiveRecord::Base.remove_connection
        end
      end
      ActiveRecord::Base.establish_connection(config)
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
    task :sequences_cssed_sequence => [:environment] do

      seq_ids = Sequence.all.map(&:id)
      config  = ActiveRecord::Base.remove_connection

      seq_ids.forkify(configatron.max_fork) do |id|
        ActiveRecord::Base.establish_connection(config)

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
      ActiveRecord::Base.establish_connection(config)
    end


    desc "Update cssed_sequence for all chains"
    task :chains_cssed_sequence => [:environment] do

      chn_ids = AaChain.all.map(&:id)
      config  = ActiveRecord::Base.remove_connection

      chn_ids.forkify(configatron.max_fork) do |id|
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
      ActiveRecord::Base.establish_connection(config)
    end

  end
end
