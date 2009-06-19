require "active_support"
require File.expand_path(File.dirname(__FILE__) + "/bipa/constants")
require File.expand_path(File.dirname(__FILE__) + "/bipa/dssp")
require File.expand_path(File.dirname(__FILE__) + "/bipa/hbplus")
require File.expand_path(File.dirname(__FILE__) + "/bipa/naccess")
require File.expand_path(File.dirname(__FILE__) + "/bipa/kdtree")
require File.expand_path(File.dirname(__FILE__) + "/bipa/usr")
require File.expand_path(File.dirname(__FILE__) + "/bipa/stats_array")
require File.expand_path(File.dirname(__FILE__) + "/bipa/nucleic_acid_binding")
require File.expand_path(File.dirname(__FILE__) + "/bipa/composed_of_residues")
require File.expand_path(File.dirname(__FILE__) + "/bipa/composed_of_atoms")

def refresh_dir(dir)
  include FileUtils

  rm_rf(dir) if File.exists?(dir)
  mkdir_p(dir)
  puts ">>> Refreshing #{dir}: done"
end
