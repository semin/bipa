namespace :bipa do
  namespace :associate do

    desc "Associate Residue with SCOP"
    task :resscop => [:environment] do

      pdb_codes = Structure.all.map(&:pdb_code)
      config    = ActiveRecord::Base.remove_connection

      pdb_codes.forkify(configatron.max_fork) do |pdb_code|
        ActiveRecord::Base.establish_connection(config)
        structure = Structure.find_by_pdb_code(pdb_code)
        domains   = ScopDomain.find_all_by_pdb_code(pdb_code)

        if domains.empty?
          $logger.warn "!!! No SCOP domains for #{pdb_code} (#{i+1}/#{pdb_codes.size})"
          ActiveRecord::Base.remove_connection
          next
        end

        domains.each do |domain|
          structure.models.first.residues.each do |residue|
            if domain.include? residue
              residue.domain = domain
              residue.save!
            end
          end
        end

        $logger.info ">>> Associating SCOP domains with #{pdb_code} (#{i+1}/#{pdb_codes.size}): done"
        ActiveRecord::Base.remove_connection
      end
      ActiveRecord::Base.establish_connection(config)
    end


    desc "Associate Residue with ResMap"
    task :resmap => [:environment] do

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
        $logger.info ">>> Total #{cnt} out of #{AaResidue.count} AaResidue entries were associated to ResMap"
      end
    end


    desc "Associate Residue with ResidueMap"
    task :residuemap => [:environment] do

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
      $logger.info ">>> Total #{cnt} out of #{AaResidue.count} AaResidue entries were associated to ResidueMap"
    end

  end
end
