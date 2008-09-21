module Bipa
  module ComposedOfAtoms

    include Bipa::Usr
    include Bipa::BindingNucleicAcids

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
    memoize :vdw_contacts

    def whbonds
      atoms.inject([]) { |s, a| s.concat(a.whbonds) }
    end
    memoize :whbonds

    def hbplus_as_donor
      atoms.inject([]) { |s, a| s.concat(a.hbplus_as_donor) }
    end
    memoize :hbplus_as_donor

    def hbplus_as_acceptor
      atoms.inject([]) { |s, a| s.concat(a.hbplus_as_acceptor) }
    end
    memoize :hbplus_as_acceptor

    def hbonds_as_donor
      atoms.inject([]) { |s, a| s.concat(a.hbonds_as_donor) }
    end
    memoize :hbonds_as_donor

    def hbonds_as_acceptor
      atoms.inject([]) { |s, a| s.concat(a.hbonds_as_acceptor) }
    end
    memoize :hbonds_as_acceptor

    def vdw_contacting_atoms
      atoms.inject([]) { |s, a| s.concat(a.vdw_contacting_atoms) }
    end
    memoize :vdw_contacting_atoms

    def whbonding_atoms
      atoms.inject([]) { |s, a| s.concat(a.whbonding_atoms) }
    end
    memoize :whbonding_atoms

    def hbplus_donors
      atoms.inject([]) { |s, a| s.concat(a.hbplus_donors) }
    end
    memoize :hbplus_donors

    def hbplus_acceptors
      atoms.inject([]) { |s, a| s.concat(a.hbplus_acceptors) }
    end
    memoize :hbplus_acceptors

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
      atoms.find(:all, :select => "atom_name").map(&:atom_name).uniq == ["CA"]
    end
    memoize :calpha_only?

    %w(unbound bound delta).each do |state|
      module_eval <<-END
        def #{state}_asa
          atoms.inject(0) { |s, a| !a.naccess.nil? ? s + a.#{state}_asa : s }
        end
        memoize :#{state}_asa

        def #{state}_asa_polar
          atoms.inject(0) { |s, a| !a.naccess.nil? && a.polar? ? s + a.#{state}_asa : s }
        end
        memoize :#{state}_asa_polar

        def #{state}_of_atom(atm)
          atoms.inject(0) { |s, a| !a.naccess.nil? && a.atom_name == atm.upcase ? s + a.#{state}_asa : s }
        end
        memoize :#{state}_of_atom
      END
    end

  end
end
