module Bipa
  module ComposedOfAtoms
    #
    # a specific set of atoms
    #
    def atoms
      raise "You should implement this 'atoms' method in your class!"
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

    # ASA related
    def calculate_unbound_asa
      atoms.inject(0) { |s, a| a.unbound_asa ? s + a.unbound_asa : s }
    end

    def calculate_bound_asa
      atoms.inject(0) { |s, a| a.bound_asa ? s + a.bound_asa : s }
    end

    def calculate_delta_asa
      calculate_unbound_asa - calculate_bound_asa
    end
    
    def asa_of_atom(atm)
      surface_atom.inject(0) { |s, a| a.atom_name == atm ? s + a.unbound_asa : s + 0 }
    end
  end
end
