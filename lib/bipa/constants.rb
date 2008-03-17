module BIPA
  module Constants
    module AminoAcids
      module Residues
        POSITIVE    = %w(ARG LYS)
        NEGATIVE    = %w(ASP GLU)
        POLAR       = %w(ASN GLN HIS SER THR)
        ALIPHATIC   = %w(ALA ILE LEU MET VAL)
        AROMATIC    = %w(PHE TRP TYR)
        PARTICULAR  = %w(CYS GLY PRO)
        UNKNOWN     = %w(UNK)
        HYDROPHILIC = POSITIVE + NEGATIVE + POLAR
        HYDROPHOBIC = ALIPHATIC + AROMATIC + PARTICULAR
        STANDARD    = HYDROPHILIC + HYDROPHOBIC

        STANDARD_ASA = {
          "ALA" =>  107.95,
          "CYS" =>  134.28,
          "ASP" =>  140.39,
          "GLU" =>  172.25,
          "PHE" =>  199.48,
          "GLY" =>   80.10,
          "HIS" =>  182.88,
          "ILE" =>  175.12,
          "LYS" =>  200.81,
          "LEU" =>  178.63,
          "MET" =>  194.15,
          "ASN" =>  143.94,
          "PRO" =>  136.13,
          "GLN" =>  178.50,
          "ARG" =>  238.76,
          "SER" =>  116.50,
          "THR" =>  139.27,
          "VAL" =>  151.44,
          "TRP" =>  249.36,
          "TYR" =>  212.76
        }
        
        ONE_LETTER_CODE = {
          # Standard Encoded Amino Acids
          "ALA" => "A",
          "ARG" => "R",
          "ASN" => "N",
          "ASP" => "D",
          "ASX" => "B",
          "CYS" => "C",
          "GLU" => "E",
          "GLN" => "Q",
          "GLX" => "Z",
          "GLY" => "G",
          "HIS" => "H",
          "ILE" => "I",
          "LEU" => "L",
          "LYS" => "K",
          "MET" => "M",
          "PHE" => "F",
          "PRO" => "P",
          "SER" => "S",
          "THR" => "T",
          "TRP" => "W",
          "TYR" => "Y",
          "VAL" => "V",
          # Amino Acid Amibiguities
          "ASX" => "B", # aspartic acid or asparagine
          "XLE" => "J", # leucine or isoleucine
          "XAA" => "X", # unknown or unspecified amino acid
          "UNK" => "X", # unknown or unspecified amino acid
          "GLZ" => "Z", # glutamic acid or glutamine
          # Special Encoded Amino Acids
          "SEC" => "U", # selenocysteine (the UniProt Knowledgebase uses "C" and a feature rather than "U"
          "PYL" => "O"  # pyrrolysine ("pyrrOlysine", the UniProt Knowledgebase uses "K" and a feature rather than "O"
        }
      end

      module Atoms
        BACKBONE  = %w(H N HN2 HA CA C O OXT HXT)
      end
    end

    module NucleicAcids
      module DNA
        module Residues
          STANDARD  = %w(DA DC DG DT)
          OTHER     = %w(DU DI)
          ALL       = STANDARD + OTHER
        end
        module Atoms
          MAJOR_GROOVE = {
            "DA" => %w(C5 C6 C8 N6 N7),
            "DT" => %w(C4 C5 C6 C7 O4),
            "DG" => %w(C5 C6 C8 N7 O6),
            "DC" => %w(C4 C5 C6 N4)
          }
          MINOR_GROOVE = {
            "DA" => %w(C2 C4 N3 N9),
            "DT" => %w(C2 N1 O2),
            "DG" => %w(N2 N3 N9 C2 C4),
            "DC" => %w(O2 N1 C2)
          }
        end
      end
      
      module RNA
        module Residues
          STANDARD  = %w(A C G U)
          OTHER     = %w(T I)
          ALL       = STANDARD + OTHER
        end
        module Atoms
        end
      end
      
      module Residues
        UNKNOWN   = %w(N)
        STANDARD  = DNA::Residues::STANDARD + RNA::Residues::STANDARD
        ALL       = DNA::Residues::ALL + RNA::Residues::ALL + UNKNOWN
      end

      module Atoms
        PHOSPHATE = %w(P OP1 OP2 OP3 HOP3 HOP2)
        SUGAR     = %w(C1' C2' C3' C4' C5' O2' O3' H1' H2' H2'' H3' H4' H5' H5' HO2' HO3')
      end
    end

    module DSSP
      HELIX = %w(H G I)
      SHEET = %w(E B)
      LOOP  = %w(T S L)
      SSES  = HELIX + SHEET + LOOP
    end
  end
end
