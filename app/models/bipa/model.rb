class Bipa::Model < ActiveRecord::Base

  include Bipa::Usr
  include Bipa::ComposedOfResidues
  include Bipa::ComposedOfAtoms

  belongs_to  :structure,
              :class_name   => "Bipa::Structure",
              :foreign_key  => "structure_id"

  has_many  :chains,
            :class_name   => "Bipa::Chain",
            :foreign_key  => "model_id",
            :dependent    => :destroy
            
  def residues
    chains.inject([]) { |s, c| s.concat(c.residues) }
  end
  
  def atoms
    residues.inject([]) { |s, r| s.concat(r.atoms)}
  end
end
