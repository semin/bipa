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

    def contacts
      atoms.inject([]) { |s, a| s.concat(a.contacts) }
    end

    def whbonds
      atoms.inject([]) { |s, a| s.concat(a.whbonds) }
    end

    def hbonds_as_donor
      atoms.inject([]) { |s, a| s.concat(a.hbonds_as_donor) }
    end

    def hbonds_as_acceptor
      atoms.inject([]) { |s, a| s.concat(a.hbonds_as_acceptor) }
    end

    def contacting_atoms
      atoms.inject([]) { |s, a| s.concat(a.contacting_atoms) }
    end

    def whbonding_atoms
      atoms.inject([]) { |s, a| s.concat(a.whbonding_atoms) }
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

    def interface_atoms
      atoms.select { |a| a.on_interface? }
    end

    def exclusive_surface_atoms
      surface_atoms - interface_atoms
    end

    def interface_atoms_binding_dna
      interface_atoms.select { |ia| ia.binding_dna? }
    end

    def interface_atoms_binding_rna
      interface_atoms.select { |ia| ia.binding_rna? }
    end

    def calpha_only?
      atoms.find(:all, :select => "atom_name").map(&:atom_name).uniq == ["CA"]
    end

    # ASA related
    %w(unbound bound delta).each do |stat|
      module_eval <<-END
        def #{stat}_asa
          @#{stat}_asa ||= atoms.inject(0) { |s, a| a.#{stat}_asa ? s + a.#{stat}_asa : s }
        end

        def #{stat}_asa_polar
          @#{stat}_asa_polar ||= atoms.inject(0) { |s, a| (a.#{stat}_asa && a.polar?) ? s + a.#{stat}_asa : s }
        end

        def #{stat}_of_atom(atm)
          atoms.inject(0) { |s, a| a.atom_name == atm.upcase ? s + a.#{stat}_asa : s }
        end
      END
    end

  end
end
