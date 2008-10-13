class Hbond < ActiveRecord::Base

  include ImportWithLoadDataInFile

  belongs_to  :donor,
              :class_name     => "Atom",
              :foreign_key    => "donor_id",
              :counter_cache  => :hbonds_as_donor_count

  belongs_to  :acceptor,
              :class_name   => "Atom",
              :foreign_key  => "acceptor_id",
              :counter_cache  => :hbonds_as_acceptor_count
end
