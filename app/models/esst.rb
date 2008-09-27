class Esst < ActiveRecord::Base

  has_many :substitutions

end

class StdEsst < Esst
end

class NaEsst < Esst
end
