namespace :bipa do
  namespace :associate do

    desc "Associate Residue with SCOP"
    task :residues_scop => [:environment] do

      pdb_codes = Structure.all.map(&:pdb_code)
      fmanager  = ForkManager.new(configatron.max_fork)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection
        pdb_codes.each_with_index do |pdb_code, i|
          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)

            structure = Structure.find_by_pdb_code(pdb_code)
            domains   = ScopDomain.find_all_by_pdb_code(pdb_code)

            if domains.empty?
              $logger.warn "!!! No SCOP domains for #{pdb_code} (#{i+1}/#{pdb_codes.size})"
            else
              domains.each do |domain|
                structure.models.first.aa_residues.each do |residue|
                  if domain.include? residue
                    residue.domain = domain
                    residue.save!
                  end
                end
              end
              $logger.info ">>> Associating SCOP domains with #{pdb_code} (#{i+1}/#{pdb_codes.size}): done"
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

      AaResidue.find_each do |aa|
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
          aa.save!
          cnt += 1
        else
          next
        end
        $logger.info("Total #{cnt} out of #{AaResidue.count} AaResidue entries were associated to ResMap")
      end
    end


    desc "Associate Residue with ResMap"
    task :residues_residue_map => [:environment] do

      cnt = 0

      AaResidue.find_each do |aa|
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
          aa.save!
          cnt += 1
        else
          next
        end
      end
      $logger.info("Total #{cnt} out of #{AaResidue.count} AaResidue entries were associated to ResidueMap")
    end

  end
end
