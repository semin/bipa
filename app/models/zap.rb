class Zap < ActiveRecord::Base

  set_table_name "zap"

  belongs_to :atom
end
