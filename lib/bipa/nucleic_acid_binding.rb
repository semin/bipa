module Bipa
  module NucleicAcidBinding
    
    # Interaction related
    def contacting_dna?
      contacting_atoms.each { |a| return true if a.dna? }
      false
    end

    def contacting_rna?
      contacting_atoms.each { |a| return true if a.rna? }
      false
    end

    def contacting_na?
      contacting_dna? or contacting_rna?
    end

    def hbonding_dna_as_donor?
      hbonding_donors.each { |a| return true if a.dna? }
      false
    end

    def hbonding_dna_as_acceptor?
      hbonding_acceptors.each { |a| return true if a.dna? }
      false
    end

    def hbonding_dna?
      hbonding_dna_as_donor? or hbonding_dna_as_acceptor?
    end

    def hbonding_rna_as_donor?
      hbonding_donors.each { |a| return true if a.rna? }
      false
    end

    def hbonding_rna_as_acceptor?
      hbonding_acceptors.each { |a| return true if a.rna? }
      false
    end

    def hbonding_rna?
      hbonding_rna_as_donor? or hbonding_rna_as_acceptor?
    end

    def whbonding_dna?
      whbonding_atoms.each { |a| return true if a.dna? }
      false
    end

    def whbonding_rna?
      whbonding_atoms.each { |a| return true if a.rna? }
      false
    end

    def whbonding_na?
      whbonding_dna? or whbonding_rna?
    end

    def binding_dna?
      contacting_dna? or whbonding_dna?
    end

    def binding_rna?
      contacting_rna? or whbonding_rna?
    end

    def binding_na?
      binding_dna? or binding_rna?
    end
    
  end
end
