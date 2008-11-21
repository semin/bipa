module Bipa
  module BindingNucleicAcids

    def hbonding_dna_as_donor?
      hbonding_acceptors.any? { |a| a.dna? }
    end

    def hbonding_dna_as_acceptor?
      hbonding_donors.any? { |a| a.dna? }
    end

    def hbonding_dna?
      hbonding_dna_base? || hbonding_dna_sugar? || hbonding_dna_phosphate?
    end

    def hbonding_rna_as_donor?
      hbonding_acceptors.any? { |a| a.rna? }
    end

    def hbonding_rna_as_acceptor?
      hbonding_donors.any? { |a| a.rna? }
    end

    def hbonding_rna?
      hbonding_rna_base? || hbonding_rna_sugar? || hbonding_rna_phosphate?
    end

    def hbonding_na?
      hbonding_dna? || hbonding_rna?
    end

    def whbonding_dna?
      whbonding_dna_base? || whbonding_dna_sugar? || whbonding_dna_phosphate?
    end

    def whbonding_rna?
      whbonding_rna_base? || whbonding_rna_sugar? || whbonding_rna_phosphate?
    end

    def whbonding_na?
      whbonding_dna? || whbonding_rna?
    end

    def vdw_contacting_dna?
      vdw_contacting_dna_base? || vdw_contacting_dna_sugar? || vdw_contacting_dna_phosphate?
    end

    def vdw_contacting_rna?
      vdw_contacting_rna_base? || vdw_contacting_rna_sugar? || vdw_contacting_rna_phosphate?
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
      if respond_to? :hbond_dna_base
        hbond_dna_base
      else
        raise "You shouldn't be here!"
        hbonding_dna_base_as_donor? || hbonding_dna_base_as_acceptor?
      end
    end

    def hbonding_dna_sugar_as_donor?
      hbonding_acceptors.any? { |a| a.dna? && a.sugar? }
    end

    def hbonding_dna_sugar_as_acceptor?
      hbonding_donors.any? { |a| a.dna? && a.sugar? }
    end

    def hbonding_dna_sugar?
      if respond_to? :hbond_dna_sugar
        hbond_dna_sugar
      else
        raise "You shouldn't be here!"
        hbonding_dna_sugar_as_donor? || hbonding_dna_sugar_as_acceptor?
      end
    end

    def hbonding_dna_phosphate_as_donor?
      hbonding_acceptors.any? { |a| a.dna? && a.phosphate? }
    end

    def hbonding_dna_phosphate_as_acceptor?
      hbonding_donors.any? { |a| a.dna? && a.phosphate? }
    end

    def hbonding_dna_phosphate?
      if respond_to? :hbond_dna_phosphate
        hbond_dna_phosphate
      else
        raise "You shouldn't be here!"
        hbonding_dna_phosphate_as_donor? || hbonding_dna_phosphate_as_acceptor?
      end
    end

    def whbonding_dna_base?
      if respond_to? :whbond_dna_base
        whbond_dna_base
      else
        raise "You shouldn't be here!"
        whbonding_atoms.any? { |a| a.dna? && a.base? }
      end
    end

    def whbonding_dna_sugar?
      if respond_to? :whbond_dna_sugar
        whbond_dna_sugar
      else
        raise "You shouldn't be here!"
        whbonding_atoms.any? { |a| a.dna? && a.sugar? }
      end
    end

    def whbonding_dna_phosphate?
      if respond_to? :whbond_dna_phosphate
        whbond_dna_phosphate
      else
        raise "You shouldn't be here!"
        whbonding_atoms.any? { |a| a.dna? && a.phosphate? }
      end
    end

    def vdw_contacting_dna_base?
      if respond_to? :vdw_dna_base
        vdw_dna_base
      else
        raise "You shouldn't be here!"
        vdw_contacting_atoms.any? { |a| a.dna? && a.base? }
      end
    end

    def vdw_contacting_dna_sugar?
      if respond_to? :vdw_dna_sugar
        vdw_dna_sugar
      else
        raise "You shouldn't be here!"
        vdw_contacting_atoms.any? { |a| a.dna? && a.sugar? }
      end
    end

    def vdw_contacting_dna_phosphate?
      if self.respond_to? :vdw_dna_phosphate
        vdw_dna_phosphate
      else
        raise "#{self.class} You shouldn't be here!"
        vdw_contacting_atoms.any? { |a| a.dna? && a.phosphate? }
      end
    end

    # rna
    def hbonding_rna_base_as_donor?
      hbonding_acceptors.any? { |a| a.rna? && a.base? }
    end

    def hbonding_rna_base_as_acceptor?
      hbonding_donors.any? { |a| a.rna? && a.base? }
    end

    def hbonding_rna_base?
      if respond_to? :hbond_rna_base
        hbond_rna_base
      else
        raise "You shouldn't be here!"
        hbonding_rna_base_as_donor? || hbonding_rna_base_as_acceptor?
      end
    end

    def hbonding_rna_sugar_as_donor?
      hbonding_acceptors.any? { |a| a.rna? && a.sugar? }
    end

    def hbonding_rna_sugar_as_acceptor?
      hbonding_donors.any? { |a| a.rna? && a.sugar? }
    end

    def hbonding_rna_sugar?
      if respond_to? :hbond_rna_sugar
        hbond_rna_sugar
      else
        raise "You shouldn't be here!"
        hbonding_rna_sugar_as_donor? || hbonding_rna_sugar_as_acceptor?
      end
    end

    def hbonding_rna_phosphate_as_donor?
      hbonding_acceptors.any? { |a| a.rna? && a.phosphate? }
    end

    def hbonding_rna_phosphate_as_acceptor?
      hbonding_donors.any? { |a| a.rna? && a.phosphate? }
    end

    def hbonding_rna_phosphate?
      if respond_to? :hbond_rna_phosphate
        hbond_rna_phosphate
      else
        raise "You shouldn't be here!"
        hbonding_rna_phosphate_as_donor? || hbonding_rna_phosphate_as_acceptor?
      end
    end

    def whbonding_rna_base?
      if respond_to? :whbond_rna_base
        whbond_rna_base
      else
        raise "You shouldn't be here!"
        whbonding_atoms.any? { |a| a.rna? && a.base? }
      end
    end

    def whbonding_rna_sugar?
      if respond_to? :whbond_rna_sugar
        whbond_rna_sugar
      else
        raise "You shouldn't be here!"
        whbonding_atoms.any? { |a| a.rna? && a.sugar? }
      end
    end

    def whbonding_rna_phosphate?
      if respond_to? :whbond_rna_phosphate
        whbond_rna_phosphate
      else
        raise "You shouldn't be here!"
        whbonding_atoms.any? { |a| a.rna? && a.phosphate? }
      end
    end

    def vdw_contacting_rna_base?
      if respond_to? :vdw_rna_base
        vdw_rna_base
      else
        raise "You shouldn't be here!"
        vdw_contacting_atoms.any? { |a| a.rna? && a.base? }
      end
    end

    def vdw_contacting_rna_sugar?
      if respond_to? :vdw_rna_sugar
        vdw_rna_sugar
      else
        raise "You shouldn't be here!"
        vdw_contacting_atoms.any? { |a| a.rna? && a.sugar? }
      end
    end

    def vdw_contacting_rna_phosphate?
      if respond_to? :vdw_rna_phosphate
        vdw_rna_phosphate
      else
        raise "You shouldn't be here!"
        vdw_contacting_atoms.any? { |a| a.rna? && a.phosphate? }
      end
    end

  end
end
