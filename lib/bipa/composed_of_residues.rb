module Bipa
  module ComposedOfResidues

    include Bipa::ComposedOfAtoms

    def residues
      raise "You should implement 'residues' when including Bipa::ComposedOfResidues"
    end

    def sorted_residues
      residues.sort_by { |r|
        if r.icode.blank?
          100000 * r.residue_code + " ".ord
        else
          100000 * r.residue_code + r.icode.ord
        end
      }
    end

    def atoms
      residues.inject([]) { |s, r| s.concat(r.atoms) }
    end

    def surface_residues
      residues.select { |r| r.on_surface? }
    end

    def buried_residues
      residues.select { |r| r.buried? }
    end

    def interface_residues
      residues.select { |r| r.on_interface? }
    end

    def exclusive_surface_residues
      surface_residues - interface_residues
    end

    def dna_binding_residues
      residues.select { |r| r.binding_dna? }
    end

    def rna_binding_residues
      residues.select { |r| r.binding_rna? }
    end

    def dna_binding_interface_residues
      interface_residues.select { |r| r.binding_dna? }
    end

    def rna_binding_interface_residues
      interface_residues.select { |r| r.binding_rna? }
    end

    def has_unks?
      residues.find(:all, :select => "residue_name").each { |r| return true if r.residue_name == "UNK" }
      false
    end

    %w[unbound bound delta].each do |stat|
      class_eval <<-END
        def #{stat}_asa_of_residue(res)
          residues.inject(0) { |s, r| r.residue_name == res.upcase ? s + r.#{stat}_asa : s }
        end

        def #{stat}_asa_of_sse(sse)
          residues.inject(0) { |s, r| !r.dssp.nil? && r.sse == sse.upcase ? s + r.#{stat}_asa : s }
        end
      END
    end


    def variation_mapped_residues
      residues.select { |r| r.variations.size > 0 }
    end

    def nssnp_mapped_residues
      residues.select { |r| r.nssnps.size > 0 }
    end

    def ssnp_mapped_residues
      residues.select { |r| r.ssnps.size > 0 }
    end

    def disease_nssnp_mapped_residues
      nssnp_mapped_residues.select { |r| r.nssnps.any? { |v| v.omims.size > 0 } }
    end
  end
end
