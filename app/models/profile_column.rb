class ProfileColumn < ActiveRecord::Base

  belongs_to :profile

  belongs_to :column

end

class StdProfileColumn < ProfileColumn
end

class NaProfileColumn < ProfileColumn
end
