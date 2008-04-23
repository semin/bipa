class Dssp < ActiveRecord::Base

  set_table_name "dssp"

  belongs_to :residue
end
