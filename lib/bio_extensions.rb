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
      def na_chains
        chains.select {|c| c.has_na? && c.chain_id !~ /^\s*$/}
      end

      def aa_chains
        chains.select {|c| (not c.has_na?) && (c.chain_id !~ /^\s*$/)}
      end
    end

    class Chain
      def has_na?
        residues.each {|r| return true if r.is_na?}
        false
      end
    end

    class Residue
      def is_dna?
        BIPA::Constants::NucleicAcids::DNA.include?(resName)
      end

      def is_rna?
        BIPA::Constants::NucleicAcids::RNA.include?(resName)
      end

      def is_na?
        BIPA::Constants::NucleicAcids::ALL.include?(resName)
      end

      def is_aa?
        not is_na?
      end

      def hydrophobicity
        if is_aa?
          if BIPA::Constants::AminoAcids::POSITIVE.include? resName
            'positive'
          elsif BIPA::Constants::AminoAcids::NEGATIVE.include? resName
            'negative'
          elsif BIPA::Constants::AminoAcids::POLAR.include? resName
            'polar'
          elsif BIPA::Constants::AminoAcids::ALIPHATIC.include? resName
            'aliphatic'
          elsif BIPA::Constants::AminoAcids::AROMATIC.include? resName
            'aromatic'
          elsif BIPA::Constants::AminoAcids::PARTICULAR.include? resName
            'particular'
          elsif BIPA::Constants::AminoAcids::UNKNOWN.include? resName
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
        def position_type
          if residue.is_na?
            if BIPA::Constants::NucleicAcids::Atoms::PHOSPHATE.include? name
              'phosphate'
            elsif BIPA::Constants::NucleicAcids::Atoms::SUGAR.include? name
              'sugar'
            else
              'base'
            end
          elsif residue.is_aa?
            if BIPA::Constants::AminoAcids::Atoms::BACKBONE.include? name
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
