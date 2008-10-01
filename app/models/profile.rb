class Profile < ActiveRecord::Base

  belongs_to :alignment

  has_many :profile_columns

  has_many :fugue_hits

end

class StdProfile < Profile
end

class NaProfile < Profile
end
