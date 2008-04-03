module Bipa
  module ComposedOfResidues

    include Bipa::ComposedOfAtoms

    def residues
      raise "'residues' method has to be implemented in your class"
    end

    def atoms
      residues.inject([]) { |s, a| s.concat(r.atoms) }
    end

    def surface_residues
      residues.select { |r| r.on_surface? }
    end

    def buried_residues
      residues.select { |r| !r.on_surface? }
    end

    def interface_residues
      residues.select { |r| r.on_interface? }
    end

    def exclusive_surface_residues
      surface_residues - interface_residues
    end

    def interface_residues_binding_dna
      interface_residues.select { |r| r.binding_dna? }
    end

    def interface_residues_binding_rna
      interface_residues.select { |r| r.binding_rna? }
    end

    %w(unbound bound delta).each do |stat|
      module_eval <<-END
        def #{stat}_asa_of_residue(res)
          residues.inject(0) { |s, r| r.residue_name == res.upcase ? s + r.#{stat}_asa : s }
        end

        def #{stat}_asa_of_sse(sse)
          residues.inject(0) { |s, r| r.secondary_structure == sse.upcase ? s + r.#{stat}_asa : s }
        end
      END
    end
  end
end
