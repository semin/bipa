class Whbond < ActiveRecord::Base

  belongs_to  :aa_water_hbond,
              :class_name   => "Hbplus",
              :foreign_key  => "aa_water_hbond_id"

  belongs_to  :na_water_hbond,
              :class_name   => "Hbplus",
              :foreign_key  => "na_water_hbond_id"
end
