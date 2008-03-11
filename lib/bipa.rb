module BIPA

  BIPA_VERSION = [0, 0, 1].extend(Comparable)

  autoload :Constants,  "bipa/constants"
  autoload :DSSP,       "bipa/dssp"
  autoload :HBPlus,     "bipa/hbplus"
  autoload :NACCESS,    "bipa/naccess"
  autoload :KDTree,     "bipa/kdtree"
  autoload :Point,      "bipa/point"
  autoload :USR,        "bipa/usr"
  autoload :NCONT,      "bipa/ncont"
  autoload :StatsArray, "bipa/stats_array"
  autoload :Cluster,    "bipa/cluster"
  autoload :NucleicAcidBinding, "bipa/nucleic_acid_binding"
  autoload :ComposedOfResidues, "bipa/composed_of_residues"
  autoload :ComposedOfAtoms,    "bipa/composed_of_atoms"

end