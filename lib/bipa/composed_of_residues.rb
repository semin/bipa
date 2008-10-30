module Bipa
  module ComposedOfResidues

    include Bipa::ComposedOfAtoms

    def residues
      raise "#residues has to be implemented in your class"
    end
    memoize :residues

    def sorted_residues
      residues.sort_by { |r|
        if r.icode.blank?
          10000 * r.residue_code + " ".ord
        else
          10000 * r.residue_code + r.icode.ord
        end
      }
    end
    memoize :sorted_residues

    def to_sequence
      sorted_residues.map(&:one_letter_code).join
    end
    memoize :to_sequence

    def atoms
      residues.inject([]) { |s, r| s.concat(r.atoms) }
    end
    memoize :atoms

    def surface_residues
      residues.select { |r| r.on_surface? }
    end
    memoize :surface_residues

    def buried_residues
      residues.select { |r| r.buried? }
    end
    memoize :buried_residues

    def interface_residues
      residues.select { |r| r.on_interface? }
    end
    memoize :interface_residues

    def exclusive_surface_residues
      surface_residues - interface_residues
    end
    memoize :exclusive_surface_residues

    def dna_binding_residues
      residues.select { |r| r.binding_dna? }
    end
    memoize :dna_binding_residues

    def rna_binding_residues
      residues.select { |r| r.binding_rna? }
    end
    memoize :rna_binding_residues

    def dna_binding_interface_residues
      interface_residues.select { |r| r.binding_dna? }
    end
    memoize :dna_binding_interface_residues

    def rna_binding_interface_residues
      interface_residues.select { |r| r.binding_rna? }
    end
    memoize :rna_binding_interface_residues

    def has_unks?
      residues.find(:all, :select => "residue_name").each { |r| return true if r.residue_name == "UNK" }
      false
    end
    memoize :has_unks?

    %w[unbound bound delta].each do |stat|
      class_eval <<-END
        def #{stat}_asa_of_residue(res)
          residues.inject(0) { |s, r| r.residue_name == res.upcase ? s + r.#{stat}_asa : s }
        end
        memoize :#{stat}_asa_of_residue

        def #{stat}_asa_of_sse(sse)
          residues.inject(0) { |s, r| !r.dssp.nil? && r.sse == sse.upcase ? s + r.#{stat}_asa : s }
        end
        memoize :#{stat}_asa_of_sse
      END
    end
  end
end
