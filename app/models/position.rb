class Position < ActiveRecord::Base

  belongs_to :sequence

  belongs_to :column

  belongs_to :residue

  def html_residue_name
    if residue
      residue.html_residue_name
    else
      residue_name
    end
  end

end
