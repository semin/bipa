module Bipa
  module BindingNucleicAcids

    def hbonding_dna_as_donor?
      hbonding_acceptors.any? { |a| a.dna? }
    end

    def hbonding_dna_as_acceptor?
      hbonding_donors.any? { |a| a.dna? }
    end

    def hbonding_dna?
      (hbonding_dna_base? || hbonding_dna_sugar? || hbonding_dna_phosphate?) or
      (hbonding_dna_as_donor? || hbonding_dna_as_acceptor?)
    end

    def hbonding_rna_as_donor?
      hbonding_acceptors.any? { |a| a.rna? }
    end

    def hbonding_rna_as_acceptor?
      hbonding_donors.any? { |a| a.rna? }
    end

    def hbonding_rna?
      (hbonding_dna_base? || hbonding_dna_sugar? || hbonding_dna_phosphate?) or
      (hbonding_rna_as_donor? || hbonding_rna_as_acceptor?)
    end

    def hbonding_na?
      hbonding_dna? || hbonding_rna?
    end

    def whbonding_dna?
      (whbonding_dna_base? || whbonding_dna_sugar? || whbonding_dna_phosphate?) or
      (whbonding_atoms.any? { |a| a.dna? })
    end

    def whbonding_rna?
      (whbonding_rna_base? || whbonding_rna_sugar? || whbonding_rna_phosphate?) or
      whbonding_atoms.any? { |a| a.rna? }
    end

    def whbonding_na?
      whbonding_dna? || whbonding_rna?
    end

    def vdw_contacting_dna?
      (vdw_contacting_dna_base? || vdw_contacting_dna_sugar? || vdw_contacting_dna_phosphate?) or
      (vdw_contacting_atoms.any? { |a| a.dna? })
    end

    def vdw_contacting_rna?
      (vdw_contacting_rna_base? || vdw_contacting_rna_sugar? || vdw_contacting_rna_phosphate?) or
      vdw_contacting_atoms.any? { |a| a.rna? }
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
      if self.respond_to? :hbond_dna_base
        self.hbond_dna_base
      else
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
      if self.respond_to? :hbond_dna_sugar
        self.hbond_dna_sugar
      else
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
      if self.respond_to? :hbond_dna_phosphate?
        self.hbond_dna_phosphate
      else
        hbonding_dna_phosphate_as_donor? || hbonding_dna_phosphate_as_acceptor?
      end
    end

    def whbonding_dna_base?
      if self.respond_to? :whbond_dna_base
        self.whbond_dna_base
      else
        whbonding_atoms.any? { |a| a.dna? && a.base? }
      end
    end

    def whbonding_dna_sugar?
      if self.respond_to? :whbond_dna_sugar
        self.whbond_dna_sugar
      else
        whbonding_atoms.any? { |a| a.dna? && a.sugar? }
      end
    end

    def whbonding_dna_phosphate?
      if self.respond_to? :whbond_dna_phosphate
        self.whbond_dna_phosphate
      else
        whbonding_atoms.any? { |a| a.dna? && a.phosphate? }
      end
    end

    def vdw_contacting_dna_base?
      if self.respond_to? :vdw_dna_base
        self.vdw_dna_base
      else
        vdw_contacting_atoms.any? { |a| a.dna? && a.base? }
      end
    end

    def vdw_contacting_dna_sugar?
      if self.respond_to? :vdw_dna_sugar
        self.vdw_dna_sugar
      else
        vdw_contacting_atoms.any? { |a| a.dna? && a.sugar? }
      end
    end

    def vdw_contacting_dna_phosphate?
      if self.respond_to? :vdw_dna_phosphate
        self.vdw_dna_phosphate
      else
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
      if self.respond_to? :hbond_rna_base
        self.hbond_rna_base
      else
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
      if self.respond_to? :hbond_rna_sugar
        self.hbond_rna_sugar
      else
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
      if self.respond_to? :hbond_rna_phosphate?
        self.hbond_rna_phosphate
      else
        hbonding_rna_phosphate_as_donor? || hbonding_rna_phosphate_as_acceptor?
      end
    end

    def whbonding_rna_base?
      if self.respond_to? :whbond_rna_base
        self.whbond_rna_base
      else
        whbonding_atoms.any? { |a| a.rna? && a.base? }
      end
    end

    def whbonding_rna_sugar?
      if self.respond_to? :whbond_rna_sugar
        self.whbond_rna_sugar
      else
        whbonding_atoms.any? { |a| a.rna? && a.sugar? }
      end
    end

    def whbonding_rna_phosphate?
      if self.respond_to? :whbond_rna_phosphate
        self.whbond_rna_phosphate
      else
        whbonding_atoms.any? { |a| a.rna? && a.phosphate? }
      end
    end

    def vdw_contacting_rna_base?
      if self.respond_to? :vdw_rna_base
        self.vdw_rna_base
      else
        vdw_contacting_atoms.any? { |a| a.rna? && a.base? }
      end
    end

    def vdw_contacting_rna_sugar?
      if self.respond_to? :vdw_rna_sugar
        self.vdw_rna_sugar
      else
        vdw_contacting_atoms.any? { |a| a.rna? && a.sugar? }
      end
    end

    def vdw_contacting_rna_phosphate?
      if self.respond_to? :vdw_rna_phosphate
        self.vdw_rna_phosphate
      else
        vdw_contacting_atoms.any? { |a| a.rna? && a.phosphate? }
      end
    end

  end
end
