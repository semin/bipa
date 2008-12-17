class InterfaceSearch < ActiveRecord::Base

  def find_interfaces
    interface_class = case interface_type
                      when "DNA"
                        DomainDnaInterface
                      when "RNA"
                        DomainRnaInterface
                      else
                        raise "Unknown interface type!"
                      end

    @results ||= interface_class.
                    in_asa_range(min_asa, max_asa).
                    in_polarity_range(min_polarity, max_polarity).
                    in_residues_count_range(min_residues_count, max_residues_count).
                    in_atoms_count_range(min_atoms_count, max_atoms_count).
                    in_hbonds_count_range(min_hbonds_count, max_hbonds_count).
                    in_whbonds_count_range(min_whbonds_count, max_whbonds_count).
                    in_vdw_contacts_count_range(min_vdw_contacts_count, max_vdw_contacts_count)


#    class_eval <<-RUBY_CODE
#      @interfaces = interface_class.
#                      in_asa_range(min_asa, max_asa).
#                      in_polarity_range(min_polarity, max_polarity).
#                      in_residues_count_range(min_residues_count, max_residues_count).
#                      in_atoms_count_range(min_atoms_count, max_atoms_count).
#                      in_hbonds_count_range(min_hbonds_count, max_hbonds_count).
#                      in_whbonds_count_range(min_whbonds_count, max_whbonds_count).
#                      in_vdw_contacts_count_range(min_vdw_contacts_count, max_vdw_contacts_count).
#                      #{AminoAcids::Residues::STANDARD.each do |aa|
#                        "in_residue_percentage_of_#{aa.downcase}_range(min_residue_percentage_of_#{aa.downcase}, max_residue_percentage_of_#{aa.downcase})"
#                      end.join(".")}.
#                      #{Sses::ALL.each do |sse|
#                        "in_sse_percentage_of_#{sse.downcase}_range(min_sse_percentage_of_#{sse.downcase}, max_sse_percentage_of_#{sse.downcase})"
#                      end.join(".")}
#
#    RUBY_CODE
  end
end

