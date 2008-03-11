namespace :bipa do
  namespace :associate do

    desc "Associate Residue with SCOP"
    task :residues_scops => [:environment] do
      structures    = Structure.find(:all)
      pdb_codes     = structures.map { |s| s.pdb_code }
      total_pdb     = structures.size
      fork_manager  = ForkManager.new(BIPA_ENV[:MAX_FORK])

      fork_manager.manage do
        config = ActiveRecord::Base.remove_connection
        pdb_codes.each_with_index do |pdb_code, i|
          fork_manager.fork do
            ActiveRecord::Base.establish_connection(config)
            
            structure = Structure.find_by_pdb_code(pdb_code)
            domains = ScopDomain.find_all_by_pdb_code(pdb_code)
            
            if domains.empty?
              puts "No SCOP domains for #{pdb_code} (#{i+1}/#{total_pdb})"
            else
              domains.each do |domain|
                structure.models.first.aa_residues.each do |aa_residue|
                  domain.residues << aa_residue if domain.include? aa_residue
                end
                domain.save!
              end
              puts "Associating SCOP domains with #{pdb_code} (#{i+1}/#{total_pdb}): done"
            end
            ActiveRecord::Base.remove_connection
          end
        end
        ActiveRecord::Base.establish_connection(config)
      end
    end

  end
end
