class Uniprot < ActiveRecord::Base

  self.abstract_class = true
  establish_connection "UNIPROT"

end


class Feature < Uniprot

  set_table_name "feature"

  belongs_to  :feature_type,
              :foreign_key => "featureType",
              :class_name => "FeatureType"

  def uniprot_url
    "http://www.uniprot.org/uniprot/#{acc}"
  end
end


class FeatureClass < Uniprot

  set_table_name "featureClass"

end


class FeatureType < Uniprot

  set_table_name "featureType"

  has_many  :features,
            :foreign_key => "featureType",
            :class_name => "FeatureType"

end


class FeatureVariant < Uniprot

  set_table_name "featureVariant"

end
