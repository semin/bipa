namespace :bipa do
  namespace :associate do

    desc "Associate PDB residues with SCOP domains"
    task :pdb_scop => [:environment] do

      pdbs  = Structure.all.map(&:pdb_code)
      fm    = ForkManager.new(configatron.max_fork)

      fm.manage do
        conn  = ActiveRecord::Base.remove_connection
        pdbs.each_with_index do |pdb, i|
          fm.fork do
            ActiveRecord::Base.establish_connection(conn)
            structure = Structure.find_by_pdb_code(pdb)
            domains   = ScopDomain.find_all_by_pdb_code(pdb)

            if domains.empty?
              $logger.warn "No SCOP domains for #{pdb} (#{i+1}/#{pdbs.size})"
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

            $logger.info "Associating SCOP domains with #{pdb} (#{i+1}/#{pdbs.size}): done"
            ActiveRecord::Base.remove_connection
          end
        end
        ActiveRecord::Base.establish_connection(conn)
      end
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
