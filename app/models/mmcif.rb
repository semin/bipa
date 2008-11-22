class Mmcif < ActiveRecord::Base

  self.abstract_class = true
  establish_connection "MMCIF"

end


class Exptl < Mmcif

  set_primary_keys :Structure, :entry_id

end


class Citation < Mmcif

  set_table_name :citation
  set_primary_keys :Structure_ID, :id

end


class Audit < Mmcif

  set_table_name :audit
  set_primary_keys :Structure_ID

end

class AuditAuthor < Mmcif

  set_table_name :audit_author
  set_primary_keys :Structure_ID

end


class Refine < Mmcif

  set_primary_keys :Structure_ID, :entry_id

end


class EntitySrcNat < Mmcif

  set_table_name :entity_src_nat
  set_primary_keys :Structure_ID, :entity_id
end


class PdbxDatabaseStatus < Mmcif

  set_table_name :pdbx_database_status
  set_primary_keys :Structure_ID, :entry_id

end


