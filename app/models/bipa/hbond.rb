class Bipa::Hbond < ActiveRecord::Base
  
  belongs_to  :hbonding_donor,
              :class_name   => "Bipa::Atom",
              :foreign_key  => "hbonding_donor_id"
              
  belongs_to  :hbonding_acceptor,
              :class_name   => "Bipa::Atom",
              :foreign_key  => "hbonding_acceptor_id"
  
end
