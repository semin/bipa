class Hbond < ActiveRecord::Base

  include ImportWithLoadDataInFile

  belongs_to  :donor,
              :class_name     => "Atom",
              :foreign_key    => "donor_id"

  belongs_to  :acceptor,
              :class_name   => "Atom",
              :foreign_key  => "acceptor_id"
end
