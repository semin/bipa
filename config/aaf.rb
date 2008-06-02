ActsAsFerret::define_index(
  'shared',
  :models => {
    Scop => {:fields => [:sunid, :stype, :sccs, :sid, :description, :resolution], :remote => true },
    GoTerm => { :fields => [:go_id, :name, :namespace, :definition], :remote => true },
    TaxonomicName => { :fields => [:name_txt, :unique_name, :name_class, :rank], :remote => true },
    Structure => {:fields => [:pdb_code, :classification, :title, :exp_method, :resolution, :r_value, :r_free, :space_group], :remote => true},
    DomainInterface => { :fields => [:type, :asa, :polarity, :hbonds_as_donor_count, :hbonds_as_acceptor_count, :contacts_count, :whbonds_count, :sunid, :sccs, :sid, :description, :resolution], :remote => true }
  },
  :ferret => {
    :default_fields => [:sunid, :stype, :sccs, :sid, :description, :resolution, :name_txt, :unique_name, :name_class, :rank, :go_id, :name, :namespace, :definition, :pdb_code, :classification, :title, :exp_method, :resolution, :r_value, :r_free, :space_group, :type, :asa, :polarity, :hbonds_as_donor_count, :hbonds_as_acceptor_count, :contacts_count, :whbonds_count, :sunid, :sccs, :sid, :description, :resolution]
  }
)
