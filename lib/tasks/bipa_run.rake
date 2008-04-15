namespace :bipa do
  namespace :run do

    include FileUtils

    desc "Run HBPLUS on each PDB file"
    task :hbplus => [:environment] do

      refresh_dir(HBPLUS_DIR) if !ENV["RESUME"]

      pdb_files = Dir[File.join(PDB_DIR, "*.pdb")]
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do

        pdb_files.each_with_index do |pdb_file, i|

          fmanager.fork do

            cwd = pwd

            pdb_code = File.basename(pdb_file, ".pdb")
            work_dir = File.join(HBPLUS_DIR, pdb_code)

            if ENV["RESUME"] && File.exists?(File.join(HBPLUS_DIR, "#{pdb_code}.hb2"))
              $logger.info("HBPLUS: #{pdb_file} (#{i + 1}/#{pdb_files.size}): skip")
              next
            end

            mkdir_p(work_dir)
            chdir(work_dir)

#            # CLEAN
#            File.open(pdb_code + ".clean_stdout", "w") do |log|
#              IO.popen(CLEAN_BIN, "r+") do |pipe|
#                pipe.puts pdb_file
#                log.puts pipe.readlines
#              end
#            end
#            $logger.info("CLEAN: #{pdb_file} (#{i + 1}/#{pdb_files.size}): done")
#
#            # NACCESS
#            new_pdb_file  = pdb_code + ".new"
#            naccess_input = File.exists?(new_pdb_file) ? new_pdb_file : pdb_file
#            naccess_cmd   = "#{NACCESS_BIN} #{naccess_input} -p 1.40 -z 0.05 -r #{NACCESS_VDW} -s #{NACCESS_STD}"
#
#            File.open(pdb_code + ".naccess.log", "w") do |log|
#              IO.popen(naccess_cmd, "r") do |pipe|
#                log.puts pipe.readlines
#              end
#            end
#            $logger.info("NACCESS: #{naccess_input} (#{i + 1}/#{pdb_files.size}): done")
#
#            # HBADD
#            hbadd_cmd = "#{HBADD_BIN} #{naccess_input} #{HET_DICT_FILE}"
#
#            File.open(pdb_code + ".hbadd.log", "w") do |log|
#              IO.popen(hbadd_cmd, "r") do |pipe|
#                log.puts pipe.readlines
#              end
#            end
#            $logger.info("HBADD: #{naccess_input} (#{i + 1}/#{pdb_files.size}): done")
#
#            # HBPLUS
#            if File.exists?(new_pdb_file)
#              hbplus_cmd = "#{HBPLUS_BIN} -x -R -q -f hbplus.rc #{new_pdb_file} #{pdb_file}"
#            else
#              hbplus_cmd = "#{HBPLUS_BIN} -x -R -q -f hbplus.rc #{pdb_file}"
#            end
#
#            File.open(pdb_code + ".hbplus.log", "w") do |log|
#              IO.popen(hbplus_cmd, "r") do |pipe|
#                log.puts pipe.readlines
#              end
#            end
#
#            mv("hbplus.rc", "#{pdb_code}.rc") if File.exists?("hbplus.rc")
#            $logger.info("HBPLUS: #{pdb_file} (#{i + 1}/#{pdb_files.size}): done")

            system("#{HBPLUS_BIN} #{pdb_file} 1>#{pdb_code}.hbplus.log 2>&1")
            move(Dir["*"], "..")
            chdir(cwd)
            rm_rf(work_dir)

            $logger.info("HBPLUS: #{pdb_file} (#{i + 1}/#{pdb_files.size}): done")
          end
        end
      end
    end # task :hbplus


    desc "Run NACCESS on each PDB file"
    task :naccess => [:environment] do

      # Run naccess for every protein-nulceic acid complex,
      # 1) protein only,
      # 2) nucleic acid only,
      # 3) and protein-nucleic acid complex

      refresh_dir(NACCESS_DIR)

      pdb_files = Dir[File.join(PDB_DIR, "*.pdb")].sort
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do

        pdb_files.each_with_index do |pdb_file, i|

          fmanager.fork do
            cwd       = pwd
            pdb_code  = File.basename(pdb_file, ".pdb")
            pdb_obj   = Bio::PDB.new(IO.read(pdb_file))
            work_dir  = File.join(NACCESS_DIR, pdb_code)

            if (pdb_obj.models.first.aa_chains.empty? ||
                pdb_obj.models.first.na_chains.empty?)
              $logger.warn("SKIP: #{pdb_file} has no amino acid chain or nucleic acid chain")
              next
            end

            mkdir(work_dir)
            chdir(work_dir)

            co_pdb_file = "#{pdb_code}_co.pdb"
            File.open(co_pdb_file, "w") do |f|
              f.puts pdb_obj.models.first.aa_chains.to_s
              f.puts pdb_obj.models.first.na_chains.to_s
              f.puts "END\n"
            end

            aa_pdb_file = "#{pdb_code}_aa.pdb"
            File.open(aa_pdb_file, "w") do |f|
              f.puts pdb_obj.models.first.aa_chains.to_s
              f.puts "END\n"
            end

            na_pdb_file = "#{pdb_code}_na.pdb"
            File.open(na_pdb_file, "w") do |f|
              f.puts pdb_obj.models.first.na_chains.to_s
              f.puts "END\n"
            end

            system("#{NACCESS_BIN} #{co_pdb_file} -h -r #{NACCESS_VDW} -s #{NACCESS_STD}")
            system("#{NACCESS_BIN} #{aa_pdb_file} -h -r #{NACCESS_VDW} -s #{NACCESS_STD}")
            system("#{NACCESS_BIN} #{na_pdb_file} -h -r #{NACCESS_VDW} -s #{NACCESS_STD}")

            cp(Dir["#{pdb_code}*"], "..")
            chdir(cwd)
            rm_r(work_dir)

            $logger.info("NACCESS: #{pdb_file} (#{i + 1}/#{pdb_files.size}): done")
          end
        end
      end
    end


    desc "Run DSSP on each PDB file"
    task :dssp => [:environment] do

      refresh_dir(DSSP_DIR)

      pdb_files = Dir[File.join(PDB_DIR, "*.pdb")]
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do

        pdb_files.each_with_index do |pdb_file, i|

          fmanager.fork do
            cwd = pwd
            chdir(DSSP_DIR)
            pdb_code = File.basename(pdb_file, '.pdb')
            system("#{DSSP_BIN} #{pdb_file} 1> #{pdb_code}.dssp 2> #{pdb_code}.dssp.err")
            $logger.info("Running DSSP on #{pdb_file} (#{i + 1}/#{pdb_files.size}): done")
            chdir(cwd)
          end
        end
      end
    end


    desc "Run blastclust for each SCOP family"
    task :blastclust => [:environment] do

      refresh_dir(BLASTCLUST_DIR)

      families = ScopFamily.registered

      families.each_with_index do |family, i|
        fam_dir   = File.join(BLASTCLUST_DIR, "#{family.sunid}")
        fam_fasta = File.join(fam_dir, "#{family.sunid}.fa")

        mkdir(fam_dir)

        File.open(fam_fasta, "w") do |file|
          domains = family.all_registered_leaf_children

          domains.each do |domain|
            sunid = domain.sunid
            fasta = domain.to_fasta

            if fasta.include?("X")
              puts "Skip: SCOP domain, #{sunid} has some unknown residues!"
              next
            end

            file.puts ">#{sunid}"
            file.puts fasta
          end
        end

        (10..100).step(10) do |si|
          blastclust_cmd =
            "blastclust " +
            "-i #{fam_fasta} "+
            "-o #{File.join(fam_dir, family.sunid.to_s + '.nr' + si.to_s + '.fa')} " +
            "-L .9 " +
            "-S #{si} " +
            "-a 2 " +
            "-p T"
            system blastclust_cmd
        end

        $logger.info("Creating non-redundant fasta files for SCOP family, #{family.sunid}: done (#{i+1}/#{families.size})")
      end
    end


    namespace :baton do

      desc "Run Baton for each SCOP family"
      task :full_pdb => [:environment] do

        sunids    = ScopFamily.registered.find(:all).map(&:sunid).sort
        full_dir  = File.join(FAMILY_DIR, "full")
        fmanager  = ForkManager.new(MAX_FORK)

        fmanager.manage do

          sunids.each_with_index do |sunid, i|

            fmanager.fork do
              cwd       = pwd
              fam_dir   = File.join(full_dir, sunid.to_s)
              pdb_list  = Dir[fam_dir + "/*.pdb"].map { |p| p.match(/(\d+)\.pdb$/)[1] }

              next unless pdb_list.size > 0

              clst_file = File.join(BLASTCLUST_DIR, sunid.to_s, "#{sunid}.nr90.fa")
              clst_list = IO.readlines(clst_file).map { |l| l.chomp.split(/\s+/) }.compact.flatten
              list      = (clst_list & pdb_list).map { |p| p + ".pdb" }

              chdir(fam_dir)
              ENV["PDB_EXT"] = ".pdb"
              File.open("LIST", "w") { |f| f.puts list.join("\n") }
              system("Baton -input /BiO/Install/Baton/data/baton.prm.current -features -pdbout -matrixout -list LIST 1>baton.log 2>&1")
              chdir(cwd)

              $logger.info("Baton with full set of SCOP Family, #{sunid}: done (#{i + 1}/#{sunids.size})")
            end
          end
        end
      end


      desc "Run Baton for representative PDB files for each SCOP Family"
      task :rep_pdb => [:environment] do

        sunids    = ScopFamily.registered.find(:all).map(&:sunid).sort
        fmanager  = ForkManager.new(MAX_FORK)

        fmanager.manage do

          sunids.each_with_index do |sunid, i|

            fmanager.fork do

              (10..100).step(10) do |si|
                cwd     = pwd
                rep_dir = File.join(FAMILY_DIR, "rep#{si}", "#{sunid}")
                chdir(rep_dir)
                system("Baton -input /home/merlin/Temp/baton.prm.current -features -pdbout -matrixout *.pdb 1> baton.log 2>&1")
                chdir(cwd)
              end

              $logger.info("BATON with representative PDB files for SCOP Family: #{sunid}: done (#{i + 1}/#{sunids.size})")
            end
          end
        end
      end


      desc "Run Baton for each subfamilies of SCOP families"
      task :sub_pdb => [:environment] do

        sunids    = ScopFamily.registered.find(:all).map(&:sunid).sort
        sub_dir   = File.join(FAMILY_DIR, "sub")
        fmanager  = ForkManager.new(MAX_FORK)

        fmanager.manage do

          sunids.each_with_index do |sunid, i|

            fmanager.fork do
              cwd     = pwd
              fam_dir = File.join(sub_dir, sunid.to_s)

              (10..100).step(10) do |si|
                rep_dir = File.join(fam_dir, "rep#{si}")

                Dir[rep_dir + "/*"].each do |subfam_dir|
                  chdir(subfam_dir)
                  system("Baton -input /home/merlin/Temp/baton.prm.current -features -pdbout -matrixout *.pdb 1> baton.log 2>&1")
                  chdir(cwd)
                end
              end

              $logger.info("BATON with subfamily PDB files for SCOP Family: #{sunid}: done (#{i + 1}/#{sunids.size})")
            end
          end
        end
      end

    end # namespace :baton


    desc "Run JOY for each SCOP family"
    task :joy => [:environment] do

      sunids    = ScopFamily.registered.find(:all).map(&:sunid)
      full_dir  = File.join(FAMILY_DIR, "full")
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do

        sunids.each_with_index do |sunid, i|

          fmanager.fork do
            cwd     = pwd
            fam_dir = File.join(full_dir, sunid.to_s)

            chdir(fam_dir)

            Dir["*.pdb"].each do |pdb_file|
              system("joy #{pdb_file} 1> #{pdb_file.gsub(/\.pdb/, '') + '.joy.log'} 2>&1")
            end

            chdir(cwd)

            $logger.info("JOY with full set of SCOP Family: #{sunid}: done (#{i + 1}/#{sunids.size})")

#            (10..100).step(10) do |si|
#
#              cwd = pwd
#              fam_dir = File.join(FAMILY_DIR, "nr#{si}", "#{sunid}")
#              chdir(fam_dir)
#              system("joy baton.ali 1> joy.log 2>&1")
#              chdir(cwd)
#
#              $logger.info("JOY with NR: #{si}, SCOP Family: #{sunid}: done (#{i + 1}/#{sunids.size})")
#            end

          end # fmanager.fork
        end
      end
    end


    desc "Run ZAP for each SCOP Domain PDB file"
    task :zap_atompot => [:environment] do

      PYCODE = '
        import os, sys
        from openeye.oechem import *
        from openeye.oezap import *

        def Output(mol, apot, showAtomTable):
            #print "Title: %s"%mol.GetTitle()
            #if showAtomTable:
            #    OEThrow.Info("Atom potentials");
            #    OEThrow.Info("Index  Elem    Charge     Potential");
            
            energy=0.0
            for atom in mol.GetAtoms():
                res = OEAtomGetResidue(atom)
                energy += atom.GetPartialCharge()*apot[atom.GetIdx()]
                if showAtomTable:
                    print "%3d %3d %2s %6.3f %6.3f %6.3f %8.3f"%(atom.GetIdx(),
                          res.GetSerialNumber(),
                          OEGetAtomicSymbol(atom.GetAtomicNum()),
                          atom.GetRadius(),
                          atom.GetFormalCharge(),
                          atom.GetPartialCharge(),
                          apot[atom.GetIdx()])

            #print "Sum of {Potential * Charge over all atoms * 0.5} in kT = %f\n" % (0.5*energy)

        def CalcAtomPotentials(itf):
            mol = OEGraphMol()
            
            ifs = oemolistream()
            if not ifs.open(itf.GetString("-in")):
                OEThrow.Fatal("Unable to open %s for reading" % itf.GetString("-in"))

            OEReadMolecule(ifs,mol)
            OEAssignBondiVdWRadii(mol)

            if not itf.GetBool("-file_charges"):
                OEMMFFAtomTypes(mol)
                OEMMFF94PartialCharges(mol)

            zap = OEZap()  
            zap.SetMolecule(mol)
            zap.SetInnerDielectric(itf.GetFloat("-epsin"))
            zap.SetBoundarySpacing(itf.GetFloat("-boundary"))
            zap.SetGridSpacing(itf.GetFloat("-grid_spacing"))

            showAtomTable = itf.GetBool("-atomtable")
            calcType = itf.GetString("-calc_type")
            if calcType=="default":        
                apot = OEFloatArray(mol.GetMaxAtomIdx())
                zap.CalcAtomPotentials(apot)
                Output(mol, apot, showAtomTable)

            elif calcType == "solvent_only":
                apot = OEFloatArray(mol.GetMaxAtomIdx())
                zap.CalcAtomPotentials(apot)

                apot2 = OEFloatArray(mol.GetMaxAtomIdx())
                zap.SetOuterDielectric(zap.GetInnerDielectric())
                zap.CalcAtomPotentials(apot2)

                # find the differences
                for atom in mol.GetAtoms():
                    idx=atom.GetIdx()
                    apot[idx] -= apot2[idx]
                    
                Output(mol, apot, showAtomTable)

            elif calcType == "remove_self":
                apot = OEFloatArray(mol.GetMaxAtomIdx())
                zap.CalcAtomPotentials(apot, True)
                Output(mol, apot, showAtomTable)

            elif calcType == "coulombic":
                epsin = itf.GetFloat("-epsin")
                x = OECoulombicSelfEnergy(mol, epsin)
                print "Coulombic Assembly Energy"
                print "  = Sum of {Potential * Charge over all atoms * 0.5} in kT = %f"%x
                apot = OEFloatArray(mol.GetMaxAtomIdx())
                OECoulombicAtomPotentials(mol, epsin, apot)
                Output(mol, apot, showAtomTable)
                
            return 0

        def SetupInterface(itf, InterfaceData):
            OEConfigure(itf, InterfaceData)
            if OECheckHelp(itf, sys.argv):
                return False
            if not OEParseCommandLine(itf, sys.argv):
                return False
            return True

        def main(InterfaceData):
            itf=OEInterface()
            if not SetupInterface(itf, InterfaceData):
                return 1
            
            return CalcAtomPotentials(itf)

        InterfaceData="""
        #zap_atompot interface definition

        !PARAMETER -in
          !TYPE string
          !BRIEF Input molecule file.
          !REQUIRED true
          !KEYLESS 1
        !END

        !PARAMETER -file_charges
          !TYPE bool
          !DEFAULT false
          !BRIEF Use partial charges from input file rather than calculating with MMFF.
        !END

        !PARAMETER -calc_type
          !TYPE string
          !DEFAULT default
          !LEGAL_VALUE default 
          !LEGAL_VALUE solvent_only 
          !LEGAL_VALUE remove_self 
          !LEGAL_VALUE coulombic 
          !LEGAL_VALUE breakdown
          !BRIEF Choose type of atom potentials to calculate
        !END

        !PARAMETER -atomtable
          !TYPE bool
          !DEFAULT false
          !BRIEF Output a table of atom potentials
        !END

        !PARAMETER -epsin
          !TYPE float
          !BRIEF Inner dielectric
          !DEFAULT 1.0
          !LEGAL_RANGE 0.0 100.0
        !END

        !PARAMETER -grid_spacing
          !TYPE float
          !DEFAULT 0.5
          !BRIEF Spacing between grid points (Angstroms)
          !LEGAL_RANGE 0.1 2.0
        !END

        !PARAMETER -boundary
          !ALIAS -buffer
          !TYPE float
          !DEFAULT 2.0
          !BRIEF Extra buffer outside extents of molecule.
          !LEGAL_RANGE 0.1 10.0
        !END
        """

        if __name__ == "__main__":
            sys.exit(main(InterfaceData))
      '

      refresh_dir(ZAP_DIR)

      zap_file = "/tmp/bipa_zap_atompot.py"
      File.open(zap_file, "w") { |f| f.puts PYCODE }

      pdb_codes = Structure.find(:all, :select => "pdb_code").map(&:pdb_code)
      fmanager  = ForkManager.new(MAX_FORK)

      fmanager.manage do

        pdb_codes.each_with_index do |pdb_code, i|

          fmanager.fork do
            [ pdb_code + "_aa.pdb", pdb_code + "_na.pdb" ].each do |pdb_file|
              system  "python #{zap_file} "
                      "-in #{File.join(NACCESS_DIR, pdb_file)} "
                      "-atomtable"
                      "> #{File.join(ZAP_DIR, pdb_stem)}.zap"
            end
          end
        end
      end
    end

  end
end
