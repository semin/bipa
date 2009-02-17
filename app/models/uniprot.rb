class Uniprot < ActiveRecord::Base

  self.abstract_class = true
  establish_connection "UNIPROT"

end


class Feature < Uniprot

  set_table_name "feature"

end


class FeatureClass < Uniprot

  set_table_name "featureClass"

end


class FeatureType < Uniprot

  set_table_name "featureType"

end


class FeatureVariant < Uniprot

  set_table_name "featureVariant"

end
