module Bipa
  module ComposedOfAtoms

    include Bipa::Usr
    include Bipa::NucleicAcidBinding

    def atoms
      raise "'atoms' method has to be implemented in your class"
    end
    memoize :atoms

    def aa_atoms
      atoms.select { |a| a.aa? }
    end
    memoize :aa_atoms

    def na_atoms
      atoms.select { |a| a.na? }
    end
    memoize :na_atoms

    def contacts
      atoms.inject([]) { |s, a| s.concat(a.contacts) }
    end
    memoize :contacts

    def whbonds
      atoms.inject([]) { |s, a| s.concat(a.whbonds) }
    end
    memoize :whbonds

    def hbonds_as_donor
      atoms.inject([]) { |s, a| s.concat(a.hbonds_as_donor) }
    end
    memoize :hbonds_as_donor

    def hbonds_as_acceptor
      atoms.inject([]) { |s, a| s.concat(a.hbonds_as_acceptor) }
    end
    memoize :hbonds_as_acceptor

    def contacting_atoms
      atoms.inject([]) { |s, a| s.concat(a.contacting_atoms) }
    end
    memoize :contacting_atoms

    def whbonding_atoms
      atoms.inject([]) { |s, a| s.concat(a.whbonding_atoms) }
    end
    memoize :whbonding_atoms

    def hbonding_donors
      atoms.inject([]) { |s, a| s.concat(a.hbonding_donors) }
    end
    memoize :hbonding_donors

    def hbonding_acceptors
      atoms.inject([]) { |s, a| s.concat(a.hbonding_acceptors) }
    end
    memoize :hbonding_acceptors

    def surface_atoms
      atoms.select { |a| a.on_surface? }
    end
    memoize :surface_atoms

    def buried_atoms
      atoms.select { |a| not a.on_surface? }
    end
    memoize :buried_atoms

    def interface_atoms
      atoms.select { |a| a.on_interface? }
    end
    memoize :interface_atoms

    def exclusive_surface_atoms
      surface_atoms - interface_atoms
    end
    memoize :exclusive_surface_atoms

    def interface_atoms_binding_dna
      interface_atoms.select { |ia| ia.binding_dna? }
    end
    memoize :interface_atoms_binding_dna

    def interface_atoms_binding_rna
      interface_atoms.select { |ia| ia.binding_rna? }
    end
    memoize :interface_atoms_binding_rna

    def calpha_only?
      atoms.map(&:atom_name).uniq == ["CA"]
    end
    memoize :calpha_only?


    # ASA related
    %w(unbound bound delta).each do |stat|
      module_eval <<-END
        def #{stat}_asa
          atoms.inject(0) { |s, a| a.#{stat}_asa ? s + a.#{stat}_asa : s }
        end
        memoize :#{stat}_asa

        def #{stat}_asa_polar
          atoms.inject(0) { |s, a| (a.#{stat}_asa && a.polar?) ? s + a.#{stat}_asa : s }
        end
        memoize :#{stat}_asa_polar

        def #{stat}_of_atom(atm)
          atoms.inject(0) { |s, a| a.atom_name == atm.upcase ? s + a.#{stat}_asa : s }
        end
        memoize :#{stat}_of_atom
      END
    end

  end
end
