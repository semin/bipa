class Alignment < ActiveRecord::Base

  belongs_to  :subfamily

  has_many  :columns
end
