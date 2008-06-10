class InterfacesController < ApplicationController

  def index
    order = case params[:sort]
            when "pdb"          then "scops.sid"
            when "sunid"        then "scops.sunid"
            when "resolution"   then "scops.resolution"
            when "type"         then "type"
            when "asa"          then "asa"
            when "no_residues"  then "residues_count"
            when "no_atoms"     then "atoms_count"
            when "no_contacts"  then "contacts_count"
            when "no_hbonds"    then "hbonds_count"
            when "no_whbonds"   then "whbonds_count"
            when "pdb_reverse"          then "scops.sid DESC"
            when "sid_reverse"          then "scops.sid DESC"
            when "resolution_reverse"   then "scops.resolution DESC"
            when "type_reverse"         then "type DESC"
            when "asa_reverse"          then "asa DESC"
            when "no_residues_reverse"  then "residues_count DESC"
            when "no_atoms_reverse"     then "atoms_count DESC"
            when "no_contacts_reverse"  then "contacts_count DESC"
            when "no_hbonds_reverse"    then "hbonds_count DESC"
            when "no_whbonds_reverse"   then "whbonds_count DESC"
            else; "scops.sid"
            end

    @interfaces = DomainInterface.paginate(
      :per_page => session[:per_page] || 10,
      :page => params[:page],
      :include => :domain,
      :select => "id, type, asa, contact_count, whbonds_count, hbonds_count, hbonds_as_donor_count, hbonds_as_acceptor_count, atoms_coutn, residues_count, scops.sid, scops.resolution",
      :order => order
    )

    respond_to do |format|
      format.html
    end
  end

  def search
    @query = params[:query]
    @hits = DomainInterface.find_with_ferret(@query, :limit => :all)

    respond_to do |format|
      format.html
    end
  end

end
