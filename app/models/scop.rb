class Scop < ActiveRecord::Base

  include Bipa::Constants

  cattr_reader :version

  @@version = "1.75"

  set_table_name :scop

  acts_as_nested_set

  %w[dna rna].each do |na|
    named_scope :"reg_#{na}", :conditions => { :"reg_#{na}" => true }

    configatron.rep_pids.each do |pid|
      named_scope :"rep#{pid}_#{na}", :conditions => { :"rep#{pid}_#{na}" => true }
    end
  end

  define_index do
    indexes :type
    indexes :sunid
    indexes :stype
    indexes :sccs
    indexes :sid
    indexes :description
  end

  def self.factory_create!(opts={})
    case opts[:stype]
    when "root" then ScopRoot.create!(opts)
    when "cl"   then ScopClass.create!(opts)
    when "cf"   then ScopFold.create!(opts)
    when "sf"   then ScopSuperFamily.create!(opts)
    when "fa"   then ScopFamily.create!(opts)
    when "dm"   then ScopProtein.create!(opts)
    when "sp"   then ScopSpecies.create!(opts)
    when "px"   then ScopDomain.create!(opts)
    else raise "Unknown SCOP hierarchy: #{opts[:stype]}"
    end
  end

  def hierarchy
    case stype
    when "root" then "Root"
    when "cl"   then "Class"
    when "cf"   then "Fold"
    when "sf"   then "Superfamily"
    when "fa"   then "Family"
    when "dm"   then "Protein"
    when "sp"   then "Species"
    when "px"   then "Domain"
    else "Unknown"
    end
  end

  def scop_domains
    leaves.select(&:rpall)
  end

  def html_sunid_link
    "http://scop.mrc-lmb.cam.ac.uk/scop/search.cgi?sunid=#{sunid}"
  end

  def html_sccs_link
    "http://scop.mrc-lmb.cam.ac.uk/scop/search.cgi?sccs=#{sccs}"
  end

  %w(dna rna).each do |na|
    class_eval <<-END
      def #{na}_interfaces
        leaves.map(&:#{na}_interfaces).flatten.compact
      end
      #memoize :#{na}_interfaces
    END
  end
#
#    %w(mean stddev).each do |property|
#      class_eval <<-END
#        def #{property}_#{na}_interface_asa(redundancy, resolution)
#          #{na}_interfaces(redundancy, resolution).map(&:asa).to_stats_array.#{property}
#        end
#        memoize :#{property}_#{na}_interface_asa
#
#        def #{property}_#{na}_interface_hbonds(redundancy, resolution)
#          #{na}_interfaces(redundancy, resolution).map { |i| (i.hbonds_as_donor_count + i.hbonds_as_acceptor_count) / i.asa * 100 }.to_stats_array.#{property}
#        end
#        memoize :#{property}_#{na}_interface_hbonds
#
#        def #{property}_#{na}_interface_whbonds(redundancy, resolution)
#          #{na}_interfaces(redundancy, resolution).map { |i| i.whbonds_count / i.asa * 100 }.to_stats_array.#{property}
#        end
#        memoize :#{property}_#{na}_interface_whbonds
#
#        def #{property}_#{na}_interface_vdw_contacts(redundancy, resolution)
#          #{na}_interfaces(redundancy, resolution).map { |i| (i.vdw_contacts_count - i.hbonds_as_donor_count - i.hbonds_as_acceptor_count) / i.asa * 100 }.to_stats_array.#{property}
#        end
#        memoize :#{property}_#{na}_interface_vdw_contacts
#
#        def #{property}_#{na}_interface_polarity(redundancy, resolution)
#          #{na}_interfaces(redundancy, resolution).map { |i| i.polarity }.to_stats_array.#{property}
#        end
#        memoize :#{property}_#{na}_interface_polarity
#      END
#
#      AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa|
#        class_eval <<-END
#          def #{property}_#{na}_interface_singlet_propensity_of_#{aa}(redundancy, resolution)
#            #{na}_interfaces(redundancy, resolution).map(&:singlet_propensity_of_#{aa}).to_stats_array.#{property}
#          end
#          memoize :#{property}_#{na}_interface_singlet_propensity_of_#{aa}
#        END
#
#        %w(hbond whbond vdw_contact).each do |intact|
#          class_eval <<-END
#            def #{property}_#{dna}_interface_#{intact}_singlet_propensity_of_#{aa}(redundancy, resolution)
#              #{na}_interfaces(redundancy, resolution).map(&:#{intact}_singlet_propensity_of_#{aa}).to_stats_array.#{property}
#            end
#            memoize :#{property}_#{dna}_interface_#{intact}_singlet_propensity_of_#{aa}
#          END
#        end
#      end
#
#      Sses::ALL.map(&:downcase).each do |sse|
#        class_eval <<-END
#          def #{property}_#{na}_interface_sse_propensity_of_#{sse}(redundancy, resolution)
#            #{na}_interfaces(redundancy, resolution).map(&:sse_propensity_of_#{sse}).to_stats_array.#{property}
#          end
#          memoize :#{property}_#{na}_interface_sse_propensity_of_#{sse}
#        END
#      end
#    end
#  end
#
#
#  %w(hbond whbond vdw_contact).each do |int|
#    %w(dna rna).each do |na|
#
#      class_eval <<-END
#        def total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}(redundancy, resolution)
#          AminoAcids::Residues::STANDARD.map(&:downcase).sum { |a|
#            send("total_observed_frequency_of_#{int}_between_\#{a}_and_#{na}", redundancy, resolution)
#          }
#        end
#        memoize :total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}
#      END
#
#      AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa|
#        class_eval <<-END
#          def total_observed_frequency_of_#{int}_between_#{aa}_and_#{na}(redundancy, resolution)
#            NucleicAcids::#{na.camelize}::Residues::STANDARD.map(&:downcase).sum { |r|
#              send("observed_frequency_of_#{int}_between_#{aa}_and_\#{r}", redundancy, resolution)
#            } + %w(sugar phosphate).sum { |m|
#              send("observed_frequency_of_#{int}_between_#{aa}_and_#{na}_\#{m}", redundancy, resolution)
#            }
#          end
#          memoize :total_observed_frequency_of_#{int}_between_#{aa}_and_#{na}
#        END
#      end
#
#      "Bipa::Constants::NucleicAcids::#{na.camelize}::Residues::STANDARD".constantize.map(&:downcase).each do |res|
#        class_eval <<-END
#          def total_observed_frequency_of_#{int}_between_amino_acids_and_#{res}(redundancy, resolution)
#            AminoAcids::Residues::STANDARD.map(&:downcase).sum { |r|
#              send("observed_frequency_of_#{int}_between_\#{r}_and_#{res}", redundancy, resolution)
#            }
#          end
#          memoize :total_observed_frequency_of_#{int}_between_amino_acids_and_#{res}
#        END
#
#        AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa|
#          class_eval <<-END
#            def observed_frequency_of_#{int}_between_#{aa}_and_#{res}(redundancy, resolution)
#              #{na}_interfaces(redundancy, resolution).sum { |i| i.frequency_of_#{int}_between_#{aa}_and_#{res} }
#            end
#            memoize :observed_frequency_of_#{int}_between_#{aa}_and_#{res}
#
#            def expected_frequency_of_#{int}_between_#{aa}_and_#{res}(redundancy, resolution)
#              result =  total_observed_frequency_of_#{int}_between_#{aa}_and_#{na}(redundancy, resolution).to_f *
#                        total_observed_frequency_of_#{int}_between_amino_acids_and_#{res}(redundancy, resolution).to_f /
#                        total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}(redundancy, resolution).to_f
#              result.nan? ? 0 : result
#            end
#            memoize :expected_frequency_of_#{int}_between_#{aa}_and_#{res}
#          END
#        end
#      end
#
#
#      %w(sugar phosphate).each do |moiety|
#        class_eval <<-END
#          def total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}_#{moiety}(redundancy, resolution)
#            AminoAcids::Residues::STANDARD.map(&:downcase).sum { |a|
#              send("observed_frequency_of_#{int}_between_\#{a}_and_#{na}_#{moiety}", redundancy, resolution)
#            }
#          end
#          memoize :total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}_#{moiety}
#        END
#
#        AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa|
#          class_eval <<-END
#            def observed_frequency_of_#{int}_between_#{aa}_and_#{na}_#{moiety}(redundancy, resolution)
#              #{na}_interfaces(redundancy, resolution).sum { |i| i.frequency_of_#{int}_between_#{aa}_and_#{moiety} }
#            end
#            memoize :observed_frequency_of_#{int}_between_#{aa}_and_#{na}_#{moiety}
#
#            def expected_frequency_of_#{int}_between_#{aa}_and_#{na}_#{moiety}(redundancy, resolution)
#              result =  total_observed_frequency_of_#{int}_between_#{aa}_and_#{na}(redundancy, resolution).to_f *
#                        total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}_#{moiety}(redundancy, resolution).to_f /
#                        total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}(redundancy, resolution).to_f
#              result.nan? ? 0 : result
#            end
#            memoize :expected_frequency_of_#{int}_between_#{aa}_and_#{na}_#{moiety}
#          END
#        end
#      end
#
#    end
#  end

end # class Scop


class ScopRoot < Scop
end


class ScopClass < Scop
end


class ScopFold < Scop
end


class ScopSuperFamily < Scop
end


class ScopFamily < Scop

  %w[dna rna].each do |na|
    has_many  :"full_#{na}_binding_family_alignments",
              :class_name   => "Full#{na.capitalize}BindingFamilyAlignment",
              :foreign_key  => "scop_id"

    configatron.rep_pids.each do |pid|
      has_many  :"rep#{pid}_#{na}_binding_family_alignments",
                :class_name   => "Rep#{pid}#{na.capitalize}BindingFamilyAlignment",
                :foreign_key  => "scop_id"

      has_many  :"sub#{pid}_#{na}_binding_subfamilies",
                :class_name   => "Sub#{pid}#{na.capitalize}BindingSubfamily",
                :foreign_key  => "scop_id"
    end
  end
end


class ScopProtein < Scop
end


class ScopSpecies < Scop
end


class ScopDomain < Scop

  include Bipa::ComposedOfResidues

  %w[dna rna].each do |na|
    configatron.rep_pids.each  do |pid|
      belongs_to  :"sub#{pid}_#{na}_binding_subfamily",
                  :class_name   => "Sub#{pid}#{na.capitalize}BindingSubfamily",
                  :foreign_key  => "sub#{pid}_#{na}_binding_subfamily_id"
    end
  end

  has_many  :dna_interfaces,
            :class_name   => "DomainDnaInterface",
            :foreign_key  => "scop_id"

  has_many  :rna_interfaces,
            :class_name   => "DomainRnaInterface",
            :foreign_key  => "scop_id"

  has_many  :residues,
            :class_name   => "Residue",
            :foreign_key  => "scop_id"

  has_many  :chains,
            :through      => :residues,
            :uniq         => true

  has_many  :atoms,
            :through      => :residues

  has_many  :sequences,
            :class_name   => "Sequence",
            :foreign_key  => "scop_id"

  has_many  :fugue_hits,
            :class_name   => "FugueHit",
            :foreign_key  => "scop_id"

  def self.find_all_by_pdb_code(pdb_code)
    find(:all, :conditions => ["sid like ?", "_#{pdb_code.downcase}%"])
  end

  def pdb_code
    sid[1..4].upcase
  end
  #memoize :pdb_code

  def resolution
    res = residues.first.chain.model.structure.resolution
    if res
      res
    else
      999
    end
  end
  #memoize :resolution

  def ranges_on_chains
    # "2hz1 A:2-124, B:1-50" => [A:2-124, B:1-50]
    description.gsub(/^\S{4}\s+/, '').gsub(/\s+/, '').split(',')
  end

  def include?(residue)
    result = false
    ranges_on_chains.each do |range|
      raise "Empty description!" if range =~ /^\s*$/
      case range
      when /^(\S):$/ # F:
        chain_code = $1
        if residue.chain.chain_code == chain_code
          result = true
        end
      when /^-$/ # -
        true
      when /^(-?\d+)-(-?\d+)$/ # 496-581
        res_from  = $1.to_i
        res_to    = $2.to_i
        if ((res_from..res_to).include?(residue[:residue_code]))
          result = true
        end
      when /^(\S):(-?\d+)-(-?\d+)$/ # A:104-157
        chain_code  = $1
        res_from    = $2.to_i
        res_to      = $3.to_i
        if ((residue.chain[:chain_code] == chain_code) &&
            (res_from..res_to).include?(residue[:residue_code]))
          result = true
        end
      else
        raise "#{self.description} should be added to Scop class!"
      end # case
    end # each
    result
  end

  def scop_class
    parent.parent.parent.parent.parent.parent
  end

  def scop_fold
    parent.parent.parent.parent.parent
  end

  def scop_superfamily
    parent.parent.parent.parent
  end

  def scop_family
    parent.parent.parent
  end

  def scop_protein
    parent.parent
  end

  def scop_species
    parent
  end

  def structure
    residues.first.chain.model.structure
  end

  def big_image
    "/images/scop/#{sunid}_500.png"
  end

  def small_image
    "/images/scop/#{sunid}_100.png"
  end

end
