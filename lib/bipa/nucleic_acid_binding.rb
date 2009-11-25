module Bipa
  module NucleicAcidBinding

    def hbonding_dna_as_donor?
      if respond_to?(:hbonds_dna_as_donor_count) && !hbonds_dna_as_donor_count.nil?
        hbonds_dna_as_donor_count > 0
      else
        hbonding_acceptors.any? { |a| a.dna? }
      end
    end

    def hbonding_dna_as_acceptor?
      if respond_to?(:hbonds_dna_as_acceptor_count) && !hbonds_dna_as_acceptor_count.nil?
        hbonds_dna_as_acceptor_count > 0
      else
        hbonding_acceptors.any? { |a| a.dna? }
      end
    end

    def hbonding_dna?
      hbonding_dna_as_donor? || hbonding_dna_as_acceptor?
      #hbonding_dna_base? || hbonding_dna_sugar? || hbonding_dna_phosphate?
    end

    def hbonding_rna_as_donor?
      if respond_to?(:hbonds_rna_as_donor_count) && !hbonds_rna_as_donor_count.nil?
        hbonds_rna_as_donor_count > 0
      else
        hbonding_acceptors.any? { |a| a.rna? }
      end
    end

    def hbonding_rna_as_acceptor?
      if respond_to?(:hbonds_rna_as_acceptor_count) && !hbonds_rna_as_acceptor_count.nil?
        hbonds_rna_as_acceptor_count > 0
      else
        hbonding_acceptors.any? { |a| a.rna? }
      end
    end

    def hbonding_rna?
      hbonding_rna_as_donor? || hbonding_rna_as_acceptor?
      #hbonding_rna_base? || hbonding_rna_sugar? || hbonding_rna_phosphate?
    end

    def hbonding_na?
      hbonding_dna? || hbonding_rna?
    end

    def whbonding_dna?
      if respond_to?(:whbonds_dna_count) && !whbonds_dna_count.nil?
        whbonds_dna_count > 0
      else
        whbonding_dna_base? || whbonding_dna_sugar? || whbonding_dna_phosphate?
      end
    end

    def whbonding_rna?
      if respond_to?(:whbonds_rna_count) && !whbonds_rna_count.nil?
        whbonds_rna_count > 0
      else
        whbonding_rna_base? || whbonding_rna_sugar? || whbonding_rna_phosphate?
      end
    end

    def whbonding_na?
      whbonding_dna? || whbonding_rna?
    end

    def vdw_contacting_dna?
      if respond_to?(:vdw_contacts_dna_count) && !vdw_contacts_dna_count.nil?
        vdw_contacts_dna_count > 0
      else
        vdw_contacting_dna_base? || vdw_contacting_dna_sugar? || vdw_contacting_dna_phosphate?
      end
    end

    def vdw_contacting_rna?
      if respond_to?(:vdw_contacts_rna_count) && !vdw_contacts_rna_count.nil?
        vdw_contacts_rna_count > 0
      else
        vdw_contacting_rna_base? || vdw_contacting_rna_sugar? || vdw_contacting_rna_phosphate?
      end
    end

    def vdw_contacting_na?
      vdw_contacting_dna? || vdw_contacting_rna?
    end

    def binding_dna?
      vdw_contacting_dna? || hbonding_dna? || whbonding_dna?
    end

    def binding_rna?
      vdw_contacting_rna? || hbonding_rna? || whbonding_rna?
    end

    def binding_na?
      binding_dna? || binding_rna?
    end

    # dna
    def hbonding_dna_base_as_donor?
      hbonding_acceptors.any? { |a| a.dna? && a.base? }
    end

    def hbonding_dna_base_as_acceptor?
      hbonding_donors.any? { |a| a.dna? && a.base? }
    end

    def hbonding_dna_base?
      hbonding_dna_base_as_donor? || hbonding_dna_base_as_acceptor?
    end

    def hbonding_dna_sugar_as_donor?
      hbonding_acceptors.any? { |a| a.dna? && a.sugar? }
    end

    def hbonding_dna_sugar_as_acceptor?
      hbonding_donors.any? { |a| a.dna? && a.sugar? }
    end

    def hbonding_dna_sugar?
      hbonding_dna_sugar_as_donor? || hbonding_dna_sugar_as_acceptor?
    end

    def hbonding_dna_phosphate_as_donor?
      hbonding_acceptors.any? { |a| a.dna? && a.phosphate? }
    end

    def hbonding_dna_phosphate_as_acceptor?
      hbonding_donors.any? { |a| a.dna? && a.phosphate? }
    end

    def hbonding_dna_phosphate?
      hbonding_dna_phosphate_as_donor? || hbonding_dna_phosphate_as_acceptor?
    end

    def whbonding_dna_base?
      whbonding_atoms.any? { |a| a.dna? && a.base? }
    end

    def whbonding_dna_sugar?
      whbonding_atoms.any? { |a| a.dna? && a.sugar? }
    end

    def whbonding_dna_phosphate?
      whbonding_atoms.any? { |a| a.dna? && a.phosphate? }
    end

    def vdw_contacting_dna_base?
      vdw_contacting_atoms.any? { |a| a.dna? && a.base? }
    end

    def vdw_contacting_dna_sugar?
      vdw_contacting_atoms.any? { |a| a.dna? && a.sugar? }
    end

    def vdw_contacting_dna_phosphate?
      vdw_contacting_atoms.any? { |a| a.dna? && a.phosphate? }
    end

    # rna
    def hbonding_rna_base_as_donor?
      hbonding_acceptors.any? { |a| a.rna? && a.base? }
    end

    def hbonding_rna_base_as_acceptor?
      hbonding_donors.any? { |a| a.rna? && a.base? }
    end

    def hbonding_rna_base?
      hbonding_rna_base_as_donor? || hbonding_rna_base_as_acceptor?
    end

    def hbonding_rna_sugar_as_donor?
      hbonding_acceptors.any? { |a| a.rna? && a.sugar? }
    end

    def hbonding_rna_sugar_as_acceptor?
      hbonding_donors.any? { |a| a.rna? && a.sugar? }
    end

    def hbonding_rna_sugar?
      hbonding_rna_sugar_as_donor? || hbonding_rna_sugar_as_acceptor?
    end

    def hbonding_rna_phosphate_as_donor?
      hbonding_acceptors.any? { |a| a.rna? && a.phosphate? }
    end

    def hbonding_rna_phosphate_as_acceptor?
      hbonding_donors.any? { |a| a.rna? && a.phosphate? }
    end

    def hbonding_rna_phosphate?
      hbonding_rna_phosphate_as_donor? || hbonding_rna_phosphate_as_acceptor?
    end

    def whbonding_rna_base?
      whbonding_atoms.any? { |a| a.rna? && a.base? }
    end

    def whbonding_rna_sugar?
      whbonding_atoms.any? { |a| a.rna? && a.sugar? }
    end

    def whbonding_rna_phosphate?
      whbonding_atoms.any? { |a| a.rna? && a.phosphate? }
    end

    def vdw_contacting_rna_base?
      vdw_contacting_atoms.any? { |a| a.rna? && a.base? }
    end

    def vdw_contacting_rna_sugar?
    end

    def vdw_contacting_rna_phosphate?
      vdw_contacting_atoms.any? { |a| a.rna? && a.phosphate? }
    end

  end
end
