class Position < ActiveRecord::Base

  belongs_to :sequence

  belongs_to :column

  belongs_to :residue

  def formatted_residue_name
    if residue
      residue.formatted_residue_name
    else
      residue_name
    end
  end

  def gap?
    residue_name == "-"
  end
end
