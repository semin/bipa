class Scop < ActiveRecord::Base

  include Bipa::Constants

  acts_as_nested_set

  ((10..100).step(10).to_a << "all").each do |identity|
    named_scope :"rep#{identity}", :conditions => { :"rep#{identity}" => true }
  end

  ((1..10).step(1).to_a << "all").each do |resolution|
    named_scope :"res#{resolution}", :conditions => { :"res#{resolution}" => true }
  end

  define_index do
    indexes sunid,        :sortable => true
    indexes stype,        :sortable => true
    indexes sccs,         :sortable => true
    indexes sid,          :sortable => true
    indexes description,  :sortable => true
    indexes resolution,   :sortable => true
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
    else; raise "Unknown SCOP hierarchy: #{opts[:stype]}"; end
  end

  def tree_title
    %Q"<a href='/scops/#{id}'>[#{stype.upcase}] #{description}</a>"
  end

  def hierarchy_and_description
    "#{hierarchy}: #{description}"
  end

  def hierarchy
    case stype
    when "root" then "Root"
    when "cl" then "Class"
    when "cf" then "Fold"
    when "sf" then "Superfamily"
    when "fa" then "Family"
    when "dm" then "Protein"
    when "sp" then "Species"
    when "px" then "Domain"
    else; "Unknown"; end
  end

  def filtered_ancestors(redundancy)
    ancestors.select(&:"rep#{redundancy}")
  end
  memoize :filtered_ancestors

  def filtered_children(redundancy)
    children.select(&:"rep#{redundancy}")
  end
  memoize :filtered_children

  def all_filtered_children(redundancy)
    all_children.select(&:"rep#{redundancy}")
  end
  memoize :all_filtered_children

  def all_filtered_leaf_children(redundancy)
    all_filtered_children(redundancy).select { |c| c.children.empty? }
  end
  memoize :all_filtered_leaf_children

  def interfaces(redundancy, resolution = nil)
    dna_interfaces(redundancy, resolution = nil) + rna_interfaces(redundancy, resolution = nil)
  end
  memoize :interfaces

  %w(dna rna).each do |na|
    class_eval <<-END
      def #{na}_interfaces(redundancy, resolution = nil)
        all_filtered_leaf_children(redundancy).map do |domain|
          if resolution
            domain.#{na}_interfaces.max_resolution(resolution = nil).find(:all)
          else
            domain.#{na}_interfaces
          end
        end.flatten.compact
      end
      memoize :#{na}_interfaces
    END

    %w(mean stddev).each do |property|
      class_eval <<-END
        def #{property}_#{na}_interface_asa(redundancy, resolution = nil)
          #{na}_interfaces(redundancy, resolution = nil).map { |i| i.asa }.to_stats_array.#{property}
        end
        memoize :#{property}_#{na}_interface_asa

        def #{property}_#{na}_interface_hbonds(redundancy, resolution = nil)
          #{na}_interfaces(redundancy, resolution = nil).map { |i| (i.hbonds_as_donor_count + i.hbonds_as_acceptor_count) / i.asa * 100 }.to_stats_array.#{property}
        end
        memoize :#{property}_#{na}_interface_hbonds

        def #{property}_#{na}_interface_whbonds(redundancy, resolution = nil)
          #{na}_interfaces(redundancy, resolution = nil).map { |i| i.whbonds_count / i.asa * 100 }.to_stats_array.#{property}
        end
        memoize :#{property}_#{na}_interface_whbonds

        def #{property}_#{na}_interface_contacts(redundancy, resolution = nil)
          #{na}_interfaces(redundancy, resolution = nil).map { |i| (i.contacts_count - i.hbonds_as_donor_count - i.hbonds_as_acceptor_count) / i.asa * 100 }.to_stats_array.#{property}
        end
        memoize :#{property}_#{na}_interface_contacts

        def #{property}_#{na}_interface_polarity(redundancy, resolution = nil)
          #{na}_interfaces(redundancy, resolution = nil).map { |i| i.polarity }.to_stats_array.#{property}
        end
        memoize :#{property}_#{na}_interface_polarity
      END

      AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa|
        class_eval <<-END
          def #{property}_#{na}_interface_singlet_propensity_of_#{aa}(redundancy, resolution = nil)
            #{na}_interfaces(redundancy, resolution = nil).map { |i| i.singlet_propensity_of_#{aa} }.to_stats_array.#{property}
          end
          memoize :#{property}_#{na}_interface_singlet_propensity_of_#{aa}
        END
      end

      Dssp::SSES.map(&:downcase).each do |sse|
        class_eval <<-END
          def #{property}_#{na}_interface_sse_propensity_of_#{sse}(redundancy, resolution = nil)
            #{na}_interfaces(redundancy, resolution = nil).map { |i| i.sse_propensity_of_#{sse} }.to_stats_array.#{property}
          end
          memoize :#{property}_#{na}_interface_sse_propensity_of_#{sse}
        END
      end
    end
  end


  %w(hbond whbond contact).each do |int|
    %w(dna rna).each do |na|

      class_eval <<-END
        def total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}(redundancy, resolution = nil)
          AminoAcids::Residues::STANDARD.map(&:downcase).sum { |a|
            send("total_observed_frequency_of_#{int}_between_\#{a}_and_#{na}", redundancy, resolution = nil)
          }
        end
        memoize :total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}
      END

      AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa|
        class_eval <<-END
          def total_observed_frequency_of_#{int}_between_#{aa}_and_#{na}(redundancy, resolution = nil)
            NucleicAcids::#{na.camelize}::Residues::STANDARD.map(&:downcase).sum { |r|
              send("observed_frequency_of_#{int}_between_#{aa}_and_\#{r}", redundancy, resolution = nil)
            } + %w(sugar phosphate).sum { |m|
              send("observed_frequency_of_#{int}_between_#{aa}_and_#{na}_\#{m}", redundancy, resolution = nil)
            }
          end
          memoize :total_observed_frequency_of_#{int}_between_#{aa}_and_#{na}
        END
      end

      "Bipa::Constants::NucleicAcids::#{na.camelize}::Residues::STANDARD".constantize.map(&:downcase).each do |res|
        class_eval <<-END
          def total_observed_frequency_of_#{int}_between_amino_acids_and_#{res}(redundancy, resolution = nil)
            AminoAcids::Residues::STANDARD.map(&:downcase).sum { |r|
              send("observed_frequency_of_#{int}_between_\#{r}_and_#{res}", redundancy, resolution = nil)
            }
          end
          memoize :total_observed_frequency_of_#{int}_between_amino_acids_and_#{res}
        END

        AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa|
          class_eval <<-END
            def observed_frequency_of_#{int}_between_#{aa}_and_#{res}(redundancy, resolution = nil)
              #{na}_interfaces(redundancy, resolution = nil).sum { |i| i.frequency_of_#{int}_between_#{aa}_and_#{res} }
            end
            memoize :observed_frequency_of_#{int}_between_#{aa}_and_#{res}

            def expected_frequency_of_#{int}_between_#{aa}_and_#{res}(redundancy, resolution = nil)
              result =  total_observed_frequency_of_#{int}_between_#{aa}_and_#{na}(redundancy, resolution = nil).to_f *
                        total_observed_frequency_of_#{int}_between_amino_acids_and_#{res}(redundancy, resolution = nil).to_f /
                        total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}(redundancy, resolution = nil).to_f
              result.nan? ? 0 : result
            end
            memoize :expected_frequency_of_#{int}_between_#{aa}_and_#{res}
          END
        end
      end


      %w(sugar phosphate).each do |moiety|
        class_eval <<-END
          def total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}_#{moiety}(redundancy, resolution = nil)
            AminoAcids::Residues::STANDARD.map(&:downcase).sum { |a|
              send("observed_frequency_of_#{int}_between_\#{a}_and_#{na}_#{moiety}", redundancy, resolution = nil)
            }
          end
          memoize :total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}_#{moiety}
        END

        AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa|
          class_eval <<-END
            def observed_frequency_of_#{int}_between_#{aa}_and_#{na}_#{moiety}(redundancy, resolution = nil)
              #{na}_interfaces(redundancy, resolution = nil).sum { |i| i.frequency_of_#{int}_between_#{aa}_and_#{moiety} }
            end
            memoize :observed_frequency_of_#{int}_between_#{aa}_and_#{na}_#{moiety}

            def expected_frequency_of_#{int}_between_#{aa}_and_#{na}_#{moiety}(redundancy, resolution = nil)
              result =  total_observed_frequency_of_#{int}_between_#{aa}_and_#{na}(redundancy, resolution = nil).to_f *
                        total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}_#{moiety}(redundancy, resolution = nil).to_f /
                        total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}(redundancy, resolution = nil).to_f
              result.nan? ? 0 : result
            end
            memoize :expected_frequency_of_#{int}_between_#{aa}_and_#{na}_#{moiety}
          END
        end
      end

    end
  end
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

  (10..100).step(10) do |si|
    has_one :"full_alignment",
            :class_name   => "FullAlignment",
            :foreign_key  => "scop_id"

    has_one :"rep#{si}_alignment",
            :class_name   => "Rep#{si}Alignment",
            :foreign_key  => "scop_id"

    has_many  :"rep#{si}_subfamilies",
              :class_name   => "Rep#{si}Subfamily",
              :foreign_key  => "scop_id"
  end
end


class ScopProtein < Scop
end


class ScopSpecies < Scop
end


class ScopDomain < Scop

  include Bipa::ComposedOfResidues

  (10..100).step(10) do |si|
    belongs_to  :"rep#{si}_subfamily",
                :class_name   => "Rep#{si}Subfamily",
                :foreign_key  => "rep#{si}_subfamily#{si}_id"
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

  has_many  :atoms,
            :through      => :residues

  has_many  :chains,
            :through      => :residues,
            :uniq         => true

  has_many  :sequences,
            :class_name   => "Sequence",
            :foreign_key  => "scop_id"

  def self.find_all_by_pdb_code(pdb_code)
    find(:all, :conditions => ["sid like ?", "%#{pdb_code.downcase}%"])
  end

  def pdb_code
    sid[1..4].upcase
  end

  def ranges_on_chains
    # "2hz1 A:2-124, B:1-50" => [A:2-124, B:1-50]
    description.gsub(/^\S{4}\s+/, '').split(',')
  end

  def include?(residue)
    result = false
    ranges_on_chains.each do |range|
      raise "Empty description!" if range =~ /^\s*$/
        case range.strip
        when /^(\S):$/ # F:
          chain_code = $1
          if residue.chain[:chain_code] == chain_code
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

  def to_pdb
    atoms.sort_by(&:atom_code).inject("") { |p, a| p + (a.to_pdb + "\n") }
  end
  memoize :to_pdb

  def to_sequence
    residues.sort_by(&:residue_code).map(&:one_letter_code).join
  end
  memoize :to_sequence

end
