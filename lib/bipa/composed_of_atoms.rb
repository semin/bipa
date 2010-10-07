module Bipa
  module ComposedOfAtoms

    include Bipa::Usr
    include Bipa::NucleicAcidBinding

    def atoms
      raise "'atoms' method has to be implemented in your class"
    end

    def aa_atoms
      atoms.select { |a| a.aa? }
    end

    def na_atoms
      atoms.select { |a| a.na? }
    end

    def dna_atoms
      atoms.select { |a| a.dna? }
    end

    def rna_atoms
      atoms.select { |a| a.rna? }
    end

    def het_atoms
      atoms.select { |a| a.het? }
    end

    def water_atoms
      atoms.select { |a| a.water? }
    end

    def vdw_contacts
      atoms.inject([]) { |s, a| s.concat(a.vdw_contacts) }
    end

    def whbonds
      atoms.inject([]) { |s, a| s.concat(a.whbonds) }
    end

    def hbplus_as_donor
      atoms.inject([]) { |s, a| s.concat(a.hbplus_as_donor) }
    end

    def hbplus_as_acceptor
      atoms.inject([]) { |s, a| s.concat(a.hbplus_as_acceptor) }
    end

    def hbonds_as_donor
      atoms.inject([]) { |s, a| s.concat(a.hbonds_as_donor) }
    end

    def hbonds_as_acceptor
      atoms.inject([]) { |s, a| s.concat(a.hbonds_as_acceptor) }
    end

    def vdw_contacting_atoms
      atoms.inject([]) { |s, a| s.concat(a.vdw_contacting_atoms) }
    end

    def whbonding_atoms
      atoms.inject([]) { |s, a| s.concat(a.whbonding_atoms) }
    end

    def hbplus_donors
      atoms.inject([]) { |s, a| s.concat(a.hbplus_donors) }
    end

    def hbplus_acceptors
      atoms.inject([]) { |s, a| s.concat(a.hbplus_acceptors) }
    end

    def hbonding_donors
      atoms.inject([]) { |s, a| s.concat(a.hbonding_donors) }
    end

    def hbonding_acceptors
      atoms.inject([]) { |s, a| s.concat(a.hbonding_acceptors) }
    end

    def surface_atoms
      atoms.select { |a| a.on_surface? }
    end

    def buried_atoms
      atoms.select { |a| not a.on_surface? }
    end

    #def interface_atoms
      #atoms.select { |a| a.on_interface? }
    #end

    #def exclusive_surface_atoms
      #surface_atoms - interface_atoms
    #end

    def dna_binding_atoms
      atoms.select { |ia| ia.binding_dna? }
    end

    def rna_binding_atoms
      atoms.select { |ia| ia.binding_rna? }
    end

    def calpha_only?
      #atoms.map(&:atom_name).uniq == ["CA"]
      atoms.find(:all,
                 :select  => "atom_name",
                 :group   => "atom_name").map(&:atom_name).uniq == ["CA"]
    end

    %w[unbound bound delta].each do |state|
      module_eval <<-END
        def #{state}_asa
          atoms.inject(0) { |s, a| a.naccess ? s + a.#{state}_asa : s }
        end

        def #{state}_asa_polar
          atoms.inject(0) { |s, a| a.naccess && a.polar? ? s + a.#{state}_asa : s }
        end

        def #{state}_of_atom(atm)
          atoms.inject(0) { |s, a| a.naccess && (a.atom_name == atm.upcase) ? s + a.#{state}_asa : s }
        end
      END
    end

    def to_pdb
      atoms.sort_by(&:atom_code).inject("") { |p, a| p + (a.to_pdb + "\n") }
    end
  end
end
