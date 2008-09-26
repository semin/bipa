class Esst < ActiveRecord::Base

  has_many :substitutions,
           :class_name  => "Substitution",
           :foreign_key => "esst_id"

end

class StdEsst < Esst
end

class NaEsst < Esst
end
