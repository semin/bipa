require File.dirname(__FILE__) + '/../test_helper'

class AtomTest < Test::Unit::TestCase

  should_belong_to  :residue

  should_have_many  :contacts

  should_have_many  :contacting_atoms,
                    :through => :contacts

  should_have_many  :hbonds_as_donor

  should_have_many  :hbonds_as_acceptor

  should_have_many  :hbonding_donors,
                    :through => :hbonds_as_acceptor

  should_have_many  :hbonding_acceptors,
                    :through => :hbonds_as_donor

  should_have_many  :whbonds

  should_have_many  :whbonding_atoms,
                    :through => :whbonds

end