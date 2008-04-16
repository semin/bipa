require "bio"
require File.expand_path(File.dirname(__FILE__) + '/bipa/constants')

module Bio

  # Patch for weird method 'three2one'
  class AminoAcid
    module Data

      def three2one(x)
        reverse[x]
      end
    end
  end


  class PDB

    def deposition_date
      if record('HEADER')[0].depDate =~ /(\d{2})-(\w{3})-(\d{2})/
        $3.to_i < 50 ? "#{$1}-#{$2}-#{'20'+$3}" : "#{$1}-#{$2}-#{'19'+$3}"
      else
        raise "Cannot find deposition date for #{entry_id}"
      end
    end

    def resolution
      remark(2).select {|r| r.respond_to? :resolution}[0].resolution
    end

    def exp_method
      record('EXPDTA')[0].technique.join
    end


    class Model

      def aa_chains
        chains.select { |c| c.aa? }
      end

      def na_chains
        chains.select { |c| c.na? }
      end
    end


    class Chain

      def aa?
        (residues.any? { |r| r.aa? } || heterogens.any? { |r| r.aa? }) && !id.blank?
      end

      def dna?
        (residues.any? { |r| r.dna? } || heterogens.any? { |r| r.dna? }) && residues.all? { |r| !r.rna? } && heterogens.all? { |r| !r.rna? } && !id.blank?
      end

      def rna?
        (residues.any? { |r| r.rna? } || heterogens.any? { |r| r.rna? }) && residues.all? { |r| !r.dna? } && heterogens.all? { |r| !r.dna? } && !id.blank?
      end

      def hna?
        ((residues.any?   { |r| r.dna? } && residues.any?   { |r| r.rna? }) ||
         (heterogens.any? { |r| r.dna? } && heterogens.any? { |r| r.rna? }) ||
         (residues.any?   { |r| r.dna? } && heterogens.any?  { |r| r.rna? }) ||
         (heterogens.any? { |r| r.dna? } && residues.any?   { |r| r.rna? })) &&
         !id.blank?
      end

      def na?
        dna? || rna? || hna?
      end

      alias :old_to_s :to_s
      def to_s
        atoms.concat(hetatms).sort_by { |a| a.serial }.map { |a| a.to_s }.join + "TER\n"
      end
    end


    class Residue

      include Bipa::Constants

      def dna?
        NucleicAcids::Dna::Residues::ALL.include?(resName.strip)
      end

      def rna?
        NucleicAcids::Rna::Residues::ALL.include?(resName.strip)
      end

      def na?
        NucleicAcids::Residues::ALL.include?(resName.strip)
      end

      def aa?
        AminoAcids::Residues::STANDARD.include?(resName.strip)
      end

      def hydrophobicity
        if aa?
          if AminoAcids::Residues::POSITIVE.include?(resName.strip)
              'positive'
          elsif AminoAcids::Residues::NEGATIVE.include?(resName.strip)
              'negative'
          elsif AminoAcids::Residues::POLAR.include?(resName.strip)
              'polar'
          elsif AminoAcids::Residues::ALIPHATIC.include?(resName.strip)
              'aliphatic'
          elsif AminoAcids::Residues::AROMATIC.include?(resName.strip)
              'aromatic'
          elsif AminoAcids::Residues::PARTICULAR.include?(resName.strip)
              'particular'
          else
            nil
          end
        else
          nil
        end
      end
    end


    class Record
      class ATOM

        include Bipa::Constants

        def position_type
          if residue.na?
            if NucleicAcids::Atoms::PHOSPHATE.include?(name.strip)
              'phosphate'
            elsif NucleicAcids::Atoms::SUGAR.include?(name.strip)
              'sugar'
            else
              'base'
            end
            # what should I do for heterogens (especially for modified amino acids)?
          elsif residue.aa?
            if AminoAcids::Atoms::BACKBONE.include?(name.strip)
              'backbone'
            else
              'sidechain'
            end
          else
            nil
          end
        end
      end
    end

  end # class PDB
end # module Bio
