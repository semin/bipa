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


    desc "Update electrostatic potential related fields of the 'atoms' table"
    task :potential => [:environment] do

      pdb_codes = Structure.find(:all, :select => "pdb_code").map(&:pdb_code)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do
        config = ActiveRecord::Base.remove_connection

        pdb_codes.each_with_index do |pdb_code, i|

          fmanager.fork do
            ActiveRecord::Base.establish_connection(config)

            structure = Structure.find_by_pdb_code(pdb_code)
            ZapAtom   = Struct.new(:index, :serial, :symbol, :radius,
                                   :formal_charge, :partial_charge, :potential)

            %w(aa na).each do |mol|
              eval <<-END
                #{mol}_zap_file   = File.join(ZAP_DIR, "#{pdb_code}_#{mol}.zap")
                #{mol}_zap_atoms  = Hash.new

                IO.foreach(#{mol}_zap_file) do |line|
                  elems = line.chomp.split(/\\s+/)
                  next unless elems.size == 7
                  zap = ZapAtom.new(elems)
                  #{mol}_zap_atoms[zap[:serial]] = zap
                end

                structure.#{mol}_atoms.each do |atom|
                  next unless #{mol}_zap_atoms[atom.atom_code]
                  zap_atom            = #{mol}_zap_atoms[atom.atom_code]
                  atom.radius         = zap_atom[:radius]
                  atom.formal_charge  = zap_atom[:formal_charge]
                  atom.partial_charge = zap_atom[:partial_charge]
                  atom.potential      = zap_atom[:potential]
                  atom.save!
                end
              END
            end

            $logger.info("Updating ASAs of #{pdb_file}: done (#{i + 1}/#{pdb_codes.size})")
            ActiveRecord::Base.remove_connection
          end # fmanager.fork
        end # pdb_codes.each_with_index
        ActiveRecord::Base.establish_connection(config)
      end # fmanager.manage
    end # task :asa


    desc "Update chain's mole_code, molecule fields"
    task :chain => [:environment] do

      structures = Structure.find(:all)

      structures.each do |structure|
        pdb_bio   = Bio::PDB.new(IO.read("./public/pdb/#{structure.pdb_code.downcase}.pdb"))
        mol_codes = {}
        molecules = {}
        mol_id    = nil
        molecule  = nil

        pdb_bio.record("COMPND")[0].compound.each do |key, value|
          case
          when key == "MOL_ID"
            mol_id = value
          when key == "MOLECULE"
            molecule = value
          when key == "CHAIN"
            mol_codes[value] = mol_id
            molecules[value] = molecule
          end
        end

        structure.models.first.chains.each do |chain|
          c = chain.chain_code
          chain.mol_code = mol_codes[c] ? mol_codes[c] : nil
          chain.molecule = molecules[c] ? molecules[c] : nil
          puts "#{chain.mol_code}: #{chain.molecule}"
          #chain.save!
        end
      end
    end

  end
end
