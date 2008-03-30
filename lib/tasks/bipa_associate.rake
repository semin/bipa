namespace :bipa do
  namespace :associate do

    desc "Associate Residue with SCOP"
    task :residues_scops => [:environment] do

      pdb_codes = Bipa::Structure.find(:all).map(&:pdb_code)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do

        config = ActiveRecord::Base.remove_connection

        pdb_codes.each_with_index do |pdb_code, i|

          fmanager.fork do

            ActiveRecord::Base.establish_connection(config)

            structure = Bipa::Structure.find_by_pdb_code(pdb_code)
            domains   = Bipa::ScopDomain.find(:all, :conditions => ["sid like ?", "%#{pdb_code.downcase}%"])

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
    task :residues_resmap => [:environment] do

      AaResidue.find(:all, :include => [{:chain => { :model => :structure }}]).each do |aa|
        resmap = ResMap.find(:first, :conditions => { :pdb => aa.chain.model.structure.pdb_code,
                                                      :pdb_chain_id => aa.chain.chain_code,
                                                      :res_num => aa.residue_code,
                                                      :ins_code => aa.icode})
        if !resmap or resmap.size > 1
          puts "Error"
        else
          puts "Found"
        end
      end

    end

  end
end
