class Esst < ActiveRecord::Base

  has_many :substitutions

end

class StdEsst < Essts
end

class NaEsst < Essts
end
