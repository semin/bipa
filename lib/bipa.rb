require "active_support"
require File.expand_path(File.dirname(__FILE__) + "/bipa/constants")
require File.expand_path(File.dirname(__FILE__) + "/bipa/dssp")
require File.expand_path(File.dirname(__FILE__) + "/bipa/hbplus")
require File.expand_path(File.dirname(__FILE__) + "/bipa/naccess")
require File.expand_path(File.dirname(__FILE__) + "/bipa/kdtree")
require File.expand_path(File.dirname(__FILE__) + "/bipa/usr")
require File.expand_path(File.dirname(__FILE__) + "/bipa/stats_array")
require File.expand_path(File.dirname(__FILE__) + "/bipa/biding_nucleic_acids")
require File.expand_path(File.dirname(__FILE__) + "/bipa/composed_of_residues")
require File.expand_path(File.dirname(__FILE__) + "/bipa/composed_of_atoms")

module Kernel

  private

  def this_method
   caller[0] =~ /`([^']*)'/ and $1
  end
end


class String
  def nil_if_blank
    self.blank? ? nil : self
  end
end


class Struct
  def to_hash
    hash = Hash.new
    self.each_pair do |sym, obj|
      hash[sym] = obj
    end
    hash
  end
end


def refresh_dir(dir)
  include FileUtils

  rm_rf(dir) if File.exists?(dir)
  mkdir_p(dir)
  puts "Refreshing #{dir}: done"
end
