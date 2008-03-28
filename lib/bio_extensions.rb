require 'rubygems'
require 'bio'
require File.expand_path(File.dirname(__FILE__) + '/bipa/constants')

module Bio
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
        residues.any? { |r| r.aa? } && !id.blank?
      end

      def dna?
        residues.any? { |r| r.dna? } && residues.all? { |r| !r.rna? } && !id.blank?
      end

      def rna?
        residues.any? { |r| r.rna? } && residues.all? { |r| !r.dna? } && !id.blank?
      end

      def hna?
        residues.any? { |r| r.dna? } && residues.any? { |r| r.rna? } && !id.blank?
      end

      def na?
        dna? or rna? or hna?
      end
    end

    class Residue

      include Bipa::Constants

      def dna?
        NucleicAcids::Dna::Residues::ALL.include?(resName)
      end

      def rna?
        NucleicAcids::Rna::Residues::ALL.include?(resName)
      end

      def na?
        NucleicAcids::Residues::ALL.include?(resName)
      end

      def aa?
        !na?
      end

      def hydrophobicity
        if self.aa?
          if AminoAcids::Residues::POSITIVE.include? resName
            'positive'
          elsif AminoAcids::Residues::NEGATIVE.include? resName
            'negative'
          elsif AminoAcids::Residues::POLAR.include? resName
            'polar'
          elsif AminoAcids::Residues::ALIPHATIC.include? resName
            'aliphatic'
          elsif AminoAcids::Residues::AROMATIC.include? resName
            'aromatic'
          elsif AminoAcids::Residues::PARTICULAR.include? resName
            'particular'
          elsif AminoAcids::Residues::UNKNOWN.include? resName
            nil
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
            if NucleicAcids::Atoms::PHOSPHATE.include? name
              'phosphate'
            elsif NucleicAcids::Atoms::SUGAR.include? name
              'sugar'
            else
              'base'
            end
          elsif residue.aa?
            if AminoAcids::Atoms::BACKBONE.include? name
              'backbone'
            else
              'sidechain'
            end
          else
            raise "#{residue} is unknown type of residue"
          end
        end
      end
    end

  end # class PDB
end # module Bio
