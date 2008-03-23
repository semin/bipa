class Bipa::Alignment < ActiveRecord::Base

  belongs_to  :subfamily,
              :class_name   => "Bipa::Subfamily",
              :foreign_key  => "subfamily_id"
end
