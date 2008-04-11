namespace :bipa do
  namespace :associate do

    desc "Associate Residue with SCOP"
    task :residues_scops => [:environment] do

      pdb_codes = Structure.find(:all).map(&:pdb_code)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do

        config = ActiveRecord::Base.remove_connection

        pdb_codes.each_with_index do |pdb_code, i|

          fmanager.fork do

            ActiveRecord::Base.establish_connection(config)

            structure = Structure.find_by_pdb_code(pdb_code)
            domains   = ScopDomain.find(:all, :conditions => ["sid like ?", "%#{pdb_code.downcase}%"])

            if domains.empty?
              puts "No SCOP domains for #{pdb_code} (#{i+1}/#{pdb_codes.size})"
            else
              domains.each do |domain|
                structure.models.first.aa_residues.each do |aa_residue|
                  domain.residues << aa_residue if domain.include? aa_residue
                end
                domain.save!
              end
              puts "Associating SCOP domains with #{pdb_code} (#{i+1}/#{pdb_codes.size}): done"
            end

            ActiveRecord::Base.remove_connection
          end
        end

        ActiveRecord::Base.establish_connection(config)
      end
    end


    desc "Associate Residue with ResMap"
    task :residues_res_map => [:environment] do

      cnt = 0

      AaResidue.find_all_in_chunks do |aa|
        res_map = ResMap.find(
          :first,
          :conditions => {
            :pdb          => aa.chain.model.structure.pdb_code,
            :pdb_chain_id => aa.chain.chain_code,
            :res_num      => aa.residue_code,
            :ins_code     => aa.icode
          }
        )

        if resmap
          aa.resmap = resmap
          cnt += 1
          $logger.info("AaResidue, #{aa.id} has been associated to ResMap, #{resmap.id}")
        else
          $logger.info("Cannot associate AaResidue, #{aa.id} to ResMap")
          next
        end

        $logger.info("Total #{cnt} out of #{AaResidue.count} AaResidue entries were associated to ResMap")
      end
    end


    desc "Associate Residue with ResMap"
    task :residues_residue_map => [:environment] do

      cnt = 0

      AaResidue.find_all_in_chunks do |aa|
        residue_map = ResidueMap.find(
          :first,
          :conditions => {
            :pdb          => aa.chain.model.structure.pdb_code,
            :pdb_chain_id => aa.chain.chain_code,
            :res_num      => aa.residue_code,
            :ins_code     => aa.icode
          }
        )

        if residue_map
          aa.residue_map = residue_map
          cnt += 1
          $logger.info("AaResidue, #{aa.id} has been associated to ResidueMap, #{residue_map.id}")
        else
          $logger.info("Cannot associate AaResidue, #{aa.id} to ResidueMap")
          next
        end

        $logger.info("Total #{cnt} out of #{AaResidue.count} AaResidue entries were associated to ResidueMap")
      end
    end

  end
end
