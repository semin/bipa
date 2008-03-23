class Bipa::Structure < ActiveRecord::Base

  is_indexed :fields => ["pdb_code", "classification", "title", "exp_method", "resolution"]

  has_many  :models,
            :class_name   => "Bipa::Model",
            :foreign_key  => "structure_id",
            :dependent    => :destroy

  def chains
    models.inject([]) { |s, m| s.concat(m.chains) }
  end
  
  def residues
    chains.inject([]) { |s, c| s.concat(c.residues) }
  end

  def atoms
    residues.inject([]) { |s, r| s.concat(r.atoms)}
  end
end
