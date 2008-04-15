namespace :bipa do
  namespace :update do

    require "logger"

    $logger = Logger.new(STDOUT)

    desc "Update ASA related fields of the 'atoms' table"
    task :asa => [:environment] do

      pdb_codes = Structure.find(:all, :select => "pdb_code").map(&:pdb_code)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        pdb_codes.each_with_index do |pdb_code, i|

          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)

            structure = Structure.find_by_pdb_code(pdb_code)

            # Load NACCESS results for every atom in the structure
            bound_asa_file      = File.join(NACCESS_DIR, "#{pdb_code}_co.asa")
            unbound_aa_asa_file = File.join(NACCESS_DIR, "#{pdb_code}_aa.asa")
            unbound_na_asa_file = File.join(NACCESS_DIR, "#{pdb_code}_na.asa")

            bound_atom_asa      = Bipa::Naccess.new(IO.read(bound_asa_file)).atom_asa
            unbound_aa_atom_asa = Bipa::Naccess.new(IO.read(unbound_aa_asa_file)).atom_asa
            unbound_na_atom_asa = Bipa::Naccess.new(IO.read(unbound_na_asa_file)).atom_asa

            structure.aa_atoms.each do |atom|
              if (bound_atom_asa[atom.atom_code] &&
                  unbound_aa_atom_asa[atom.atom_code])
                atom.bound_asa    = bound_atom_asa[atom.atom_code]
                atom.unbound_asa  = unbound_aa_atom_asa[atom.atom_code]
                atom.delta_asa    = atom.unbound_asa - atom.bound_asa
                atom.save!
              end
            end

            structure.na_atoms.each do |atom|
              if (bound_atom_asa[atom.atom_code] &&
                  unbound_na_atom_asa[atom.atom_code])
                atom.bound_asa    = bound_atom_asa[atom.atom_code]
                atom.unbound_asa  = unbound_na_atom_asa[atom.atom_code]
                atom.delta_asa    = atom.unbound_asa - atom.bound_asa
                atom.save!
              end
            end

            $logger.info("Updating ASAs of #{pdb_file}: done (#{i + 1}/#{pdb_codes.size})")
            ActiveRecord::Base.remove_connection
          end # fmanager.fork
        end # pdb_codes.each_with_index
        ActiveRecord::Base.establish_connection(config)
      end # fmanager.manage
    end # task :asa

  end
end
