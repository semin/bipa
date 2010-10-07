require "active_support"
require 'matrix'
require "fileutils"
require 'bio_extensions'
require 'math_extensions'
require 'array_extensions'
require 'vector_extensions'
require 'kernel_extentions'
require 'string_extensions'
require 'struct_extensions'
require 'numeric_extensions'
require 'pathname_extensions'

include FileUtils

curdir = Pathname.new(__FILE__).dirname

require curdir.join("./bipa/constants").expand_path
require curdir.join("./bipa/dssp").expand_path
require curdir.join("./bipa/esst").expand_path
require curdir.join("./bipa/essts").expand_path
require curdir.join("./bipa/hbplus").expand_path
require curdir.join("./bipa/naccess").expand_path
require curdir.join("./bipa/kdtree").expand_path
require curdir.join("./bipa/usr").expand_path
require curdir.join("./bipa/essts").expand_path
require curdir.join("./bipa/tmalign").expand_path
require curdir.join("./bipa/stats_array").expand_path
require curdir.join("./bipa/nucleic_acid_binding").expand_path
require curdir.join("./bipa/composed_of_residues").expand_path
require curdir.join("./bipa/composed_of_atoms").expand_path

