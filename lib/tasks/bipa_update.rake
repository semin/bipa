namespace :bipa do
  namespace :update do

    desc "Update Residue ASA"
    task :residues_asa => [:environment] do

      structures    = Structure.find(:all)
      total_pdb     = structures.size
      fork_manager  = ForkManager.new(BIPA_ENV[:MAX_FORK])

      fork_manager.manage do
        config = ActiveRecord::Base.remove_connection

        structures.each_with_index do |structure, i|

          fork_manager.fork do

            ActiveRecord::Base.establish_connection(config)
            structure.models.first.residues.each do |residue|
              begin
                delta_asa = residue.calculate_asa_unbound - residue.calculate_asa_bound
              rescue
                delta_asa = nil
              ensure
                residue.update_attribute(:asa_bound,    residue.calculate_asa_bound)
                residue.update_attribute(:asa_unbound,  residue.calculate_asa_unbound)
                residue.update_attribute(:delta_asa,    delta_asa)
              end
            end

            puts "Updating Residues' ASA in #{structure.pdb_code} (#{i+1}/#{total_pdb}): done"
            ActiveRecord::Base.remove_connection
          end
        end

        ActiveRecord::Base.establish_connection(config)
      end
    end

  end
end

