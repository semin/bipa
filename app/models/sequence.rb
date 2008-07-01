class Sequence < ActiveRecord::Base

  belongs_to  :alignment

  belongs_to  :domain,
              :class_name => "ScopDomain",
              :foreign_key  => "scop_id"

  belongs_to  :chain

  has_many  :positions,
            :order  => "number"

  delegate  :resolution, :to => :domain

  def sequence
    positions.map(&:residue_name).join
  end

  def html_sequence
    positions.map(&:html_residue_name).join
  end
end
