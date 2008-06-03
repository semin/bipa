class Scop < ActiveRecord::Base

  include Bipa::Constants

  acts_as_nested_set

  acts_as_ferret  :fields => [ :sunid, :stype, :sccs, :sid, :description, :resolution ],
                  :remote => true

  ((10..100).select { |i| i % 10 == 0 } << "all").each do |si|
    named_scope :"rep#{si}", :conditions => { :"rep#{si}" => true }
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

  def self.search(query)
    find(:all, :conditions => ["description LIKE ?", "%#{query}%"])
  end

  def tree_title
    %Q^<a href="#" onclick="new Ajax.Updater('main_container', '/scop/tabs/#{id}', { asynchronous:true, evalScripts:true }); return false;">[#{stype.upcase}] #{description}</a>^
  end

  def hierarchy_and_description
    "#{hierarchy}: #{description}"
  end

  def hierarchy
    case stype
    when "cl" then "Class"
    when "cf" then "Fold"
    when "sf" then "Superfamily"
    when "fa" then "Family"
    when "dm" then "Protein"
    when "sp" then "Species"
    when "px" then "Domain"
    else; "Unknown"; end
  end

  def registered_ancestors(redundancy)
    ancestors.select(&:"rep#{redundancy}")
  end

  def registered_children(redundancy)
    children.select(&:"rep#{redundancy}")
  end

  def all_registered_children(redundancy)
    all_children.select(&:"rep#{redundancy}")
  end

  def all_registered_leaf_children(redundancy)
    all_registered_children(redundancy).select { |c| c.children.empty? }
  end

  %w(dna rna).each do |na|
    class_eval <<-END
      def #{na}_interfaces(redundancy, resolution)
        all_registered_leaf_children(redundancy).map do |domain|
          if resolution
            domain.#{na}_interfaces.max_resolution(resolution).find(:all)
          else
            domain.#{na}_interfaces
          end
        end.flatten.compact
      end
    END

    %w(mean stddev).each do |property|
      class_eval <<-END
        def #{property}_#{na}_interface_asa(redundancy, resolution)
          #{na}_interfaces(redundancy, resolution).map { |i| i.asa }.to_stats_array.#{property}
        end
        memoize :#{property}_#{na}_interface_asa

        def #{property}_#{na}_interface_hbonds(redundancy, resolution)
          #{na}_interfaces(redundancy, resolution).map { |i| (i.hbonds_as_donor_count + i.hbonds_as_acceptor_count) / i.asa * 100 }.to_stats_array.#{property}
        end
        memoize :#{property}_#{na}_interface_hbonds

        def #{property}_#{na}_interface_whbonds(redundancy, resolution)
          #{na}_interfaces(redundancy, resolution).map { |i| i.whbonds_count / i.asa * 100 }.to_stats_array.#{property}
        end
        memoize :#{property}_#{na}_interface_whbonds

        def #{property}_#{na}_interface_contacts(redundancy, resolution)
          #{na}_interfaces(redundancy, resolution).map { |i| (i.contacts_count - i.hbonds_as_donor_count - i.hbonds_as_acceptor_count) / i.asa * 100 }.to_stats_array.#{property}
        end
        memoize :#{property}_#{na}_interface_contacts

        def #{property}_#{na}_interface_polarity(redundancy, resolution)
          #{na}_interfaces(redundancy, resolution).map { |i| i.polarity }.to_stats_array.#{property}
        end
        memoize :#{property}_#{na}_interface_polarity
      END

      AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa|
        class_eval <<-END
          def #{property}_#{na}_interface_singlet_propensity_of_#{aa}(redundancy, resolution)
            #{na}_interfaces(redundancy, resolution).map { |i| i.singlet_propensity_of_#{aa} }.to_stats_array.#{property}
          end
          memoize :#{property}_#{na}_interface_singlet_propensity_of_#{aa}
        END
      end

      Dssp::SSES.map(&:downcase).each do |sse|
        class_eval <<-END
          def #{property}_#{na}_interface_sse_propensity_of_#{sse}(redundancy, resolution)
            #{na}_interfaces(redundancy, resolution).map { |i| i.sse_propensity_of_#{sse} }.to_stats_array.#{property}
          end
          memoize :#{property}_#{na}_interface_sse_propensity_of_#{sse}
        END
      end
    end
  end


  %w(hbond whbond contact).each do |int|
    %w(dna rna).each do |na|
      na_residues = "Bipa::Constants::NucleicAcids::#{na.camelize}::Residues::STANDARD".constantize.map(&:downcase)

      class_eval <<-END
        def total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}(redundancy, resolution)
          AminoAcids::Residues::STANDARD.map(&:downcase).sum { |a|
            send("total_observed_frequency_of_#{int}_between_\#{a}_and_#{na}", redundancy, resolution)
          }
        end
        memoize :total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}
      END

      AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa|
        class_eval <<-END
          def total_observed_frequency_of_#{int}_between_#{aa}_and_#{na}(redundancy, resolution)
            na_residues.sum { |r|
              send("observed_frequency_of_#{int}_between_#{aa}_and_\#{r}", redundancy, resolution)
            } + %w(sugar phosphate).sum { |m|
              send("observed_frequency_of_#{int}_between_#{aa}_and_#{na}_\#{m}", redundancy, resolution)
            }
          end
          memoize :total_observed_frequency_of_#{int}_between_#{aa}_and_#{na}
        END
      end

      na_residues.each do |res|
        class_eval <<-END
          def total_observed_frequency_of_#{int}_between_amino_acids_and_#{res}(redundancy, resolution)
            AminoAcids::Residues::STANDARD.map(&:downcase).sum { |r|
              send("observed_frequency_of_#{int}_between_\#{r}_and_#{res}", redundancy, resolution)
            }
          end
          memoize :total_observed_frequency_of_#{int}_between_amino_acids_and_#{res}
        END

        AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa|
          class_eval <<-END
            def observed_frequency_of_#{int}_between_#{aa}_and_#{res}(redundancy, resolution)
              #{na}_interfaces(redundancy, resolution).sum { |i| i.frequency_of_#{int}_between_#{aa}_and_#{res} }
            end
            memoize :observed_frequency_of_#{int}_between_#{aa}_and_#{res}

            def expected_frequency_of_#{int}_between_#{aa}_and_#{res}(redundancy, resolution)
              result =  total_observed_frequency_of_#{int}_between_#{aa}_and_#{na}(redundancy, resolution).to_f *
                        total_observed_frequency_of_#{int}_between_amino_acids_and_#{res}(redundancy, resolution).to_f /
                        total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}(redundancy, resolution).to_f
              result.nan? ? 0 : result
            end
            memoize :expected_frequency_of_#{int}_between_#{aa}_and_#{res}
          END
        end
      end


      %w(sugar phosphate).each do |moiety|
        class_eval <<-END
          def total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}_#{moiety}(redundancy, resolution)
            AminoAcids::Residues::STANDARD.map(&:downcase).sum { |a|
              send("observed_frequency_of_#{int}_between_\#{a}_and_#{na}_#{moiety}", redundancy, resolution)
            }
          end
          memoize :total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}_#{moiety}
        END

        AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa|
          class_eval <<-END
            def observed_frequency_of_#{int}_between_#{aa}_and_#{na}_#{moiety}(redundancy, resolution)
              #{na}_interfaces(redundancy, resolution).sum { |i| i.frequency_of_#{int}_between_#{aa}_and_#{moiety} }
            end
            memoize :observed_frequency_of_#{int}_between_#{aa}_and_#{na}_#{moiety}

            def expected_frequency_of_#{int}_between_#{aa}_and_#{na}_#{moiety}(redundancy, resolution)
              result =  total_observed_frequency_of_#{int}_between_#{aa}_and_#{na}(redundancy, resolution).to_f *
                        total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}_#{moiety}(redundancy, resolution).to_f /
                        total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}(redundancy, resolution).to_f
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

  def resolution
    chains.first.model.structure.resolution
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
