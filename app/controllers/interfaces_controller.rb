class InterfacesController < ApplicationController

  def index
    order = case params[:sort]
            when "pdb"          then "scops.sid"
            when "sid"          then "scops.sid"
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

    @interfaces = DomainInterface.paginate(:per_page => 10,
                                           :page => params[:page],
                                           :include => :domain,
                                           :order => order)
    respond_to do |format|
      format.html
      format.js { render :template => "index.html.erb" }
    end
  end
end
