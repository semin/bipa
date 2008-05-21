class Scop < ActiveRecord::Base

  include Bipa::Constants

  acts_as_nested_set

  has_finder :registered, :conditions => { :registered => true }

  def self.factory_create!(opt={})
    case opt[:stype]
    when 'root' then ScopRoot.create!(opt)
    when 'cl'   then ScopClass.create!(opt)
    when 'cf'   then ScopFold.create!(opt)
    when 'sf'   then ScopSuperFamily.create!(opt)
    when 'fa'   then ScopFamily.create!(opt)
    when 'dm'   then ScopProtein.create!(opt)
    when 'sp'   then ScopSpecies.create!(opt)
    when 'px'   then ScopDomain.create!(opt)
    else; raise "Unknown SCOP hierarchy: #{opt[:stype]}"; end
  end

  def tree_title
    if self.is_a? ScopFamily
      %Q^<a href="#" onclick="new Ajax.Updater('main_content', '/scop/tabs/#{id}', {asynchronous:true, evalScripts:true, onLoading:function(request){ Element.hide('main_content'); Element.show('main_spinner') }, onComplete:function(request){ Element.hide('main_spinner'); Element.show('main_content'); }}); return false;">[#{stype.upcase}] #{description}</a>^
    else
      %Q^<a href="#">[#{stype.upcase}] #{description}</a>^
    end
  end

  def hierarchy_and_description
    "#{hierarchy}: #{description}"
  end

  def hierarchy
    case stype
    when 'cl' then 'Class'
    when 'cf' then 'Fold'
    when 'sf' then 'Superfamily'
    when 'fa' then 'Family'
    when 'dm' then 'Protein'
    when 'sp' then 'Species'
    when 'px' then 'Domain'
    else; 'Unknown'; end
  end

  def registered_ancestors
    ancestors.select(&:registered)
  end

  def registered_children
    children.select(&:registered)
  end

  def all_registered_children
    all_children.select(&:registered)
  end

  def all_registered_leaf_children
    all_registered_children.select { |c| c.children.empty? }
  end

  def dna_interfaces
    all_registered_leaf_children.map(&:dna_interfaces).flatten.compact
  end

  def rna_interfaces
    all_registered_leaf_children.map(&:rna_interfaces).flatten.compact
  end

  %w(dna rna).each do |na|
    %w(mean stddev).each do |property|
      class_eval <<-END
        def #{property}_#{na}_interface_asa
          #{na}_interfaces.map { |i| i.asa }.to_stats_array.#{property}
        end
        memoize :#{property}_#{na}_interface_asa

        def #{property}_#{na}_interface_hbonds
          #{na}_interfaces.map { |i| (i.hbonds_as_donor.size + i.hbonds_as_acceptor.size) / i.asa * 100 }.to_stats_array.#{property}
        end
        memoize :#{property}_#{na}_interface_hbonds

        def #{property}_#{na}_interface_whbonds
          #{na}_interfaces.map { |i| i.whbonds.size / i.asa * 100 }.to_stats_array.#{property}
        end
        memoize :#{property}_#{na}_interface_whbonds

        def #{property}_#{na}_interface_contacts
          #{na}_interfaces.map { |i| (i.contacts.size - i.hbonds_as_donor.size - i.hbonds_as_acceptor.size) / i.asa * 100 }.to_stats_array.#{property}
        end
        memoize :#{property}_#{na}_interface_contacts

        def #{property}_#{na}_interface_polarity
          #{na}_interfaces.map { |i| i.polarity }.to_stats_array.#{property}
        end
        memoize :#{property}_#{na}_interface_polarity
      END

      AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa|
        class_eval <<-END
          def #{property}_#{na}_interface_singlet_propensity_of_#{aa}
            #{na}_interfaces.map { |i| i.singlet_propensity_of_#{aa} }.to_stats_array.#{property}
          end
          memoize :#{property}_#{na}_interface_singlet_propensity_of_#{aa}
        END
      end

      Dssp::SSES.map(&:downcase).each do |sse|
        class_eval <<-END
          def #{property}_#{na}_interface_sse_propensity_of_#{sse}
            #{na}_interfaces.map { |i| i.sse_propensity_of_#{sse} }.to_stats_array.#{property}
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
        def total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}
          AminoAcids::Residues::STANDARD.map(&:downcase).sum { |a|
            send("total_observed_frequency_of_#{int}_between_\#{a}_and_#{na}")
          }
        end
        memoize :total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}
      END

      AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa|
        class_eval <<-END
          def total_observed_frequency_of_#{int}_between_#{aa}_and_#{na}
            na_residues.sum { |r|
              send("observed_frequency_of_#{int}_between_#{aa}_and_\#{r}")
            } + %w(sugar phosphate).sum { |m|
              send("observed_frequency_of_#{int}_between_#{aa}_and_#{na}_\#{m}")
            }
          end
          memoize :total_observed_frequency_of_#{int}_between_#{aa}_and_#{na}
        END
      end

      na_residues.each do |res|
        class_eval <<-END
          def total_observed_frequency_of_#{int}_between_amino_acids_and_#{res}
            AminoAcids::Residues::STANDARD.map(&:downcase).sum { |r|
              send("observed_frequency_of_#{int}_between_\#{r}_and_#{res}")
            }
          end
          memoize :total_observed_frequency_of_#{int}_between_amino_acids_and_#{res}
        END

        AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa|
          class_eval <<-END
            def observed_frequency_of_#{int}_between_#{aa}_and_#{res}
              #{na}_interfaces.sum { |i| i.frequency_of_#{int}_between_#{aa}_and_#{res} }
            end
            memoize :observed_frequency_of_#{int}_between_#{aa}_and_#{res}

            def expected_frequency_of_#{int}_between_#{aa}_and_#{res}
              result =  total_observed_frequency_of_#{int}_between_#{aa}_and_#{na}.to_f *
                        total_observed_frequency_of_#{int}_between_amino_acids_and_#{res}.to_f /
                        total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}.to_f
              result.nan? ? 0 : result
            end
            memoize :expected_frequency_of_#{int}_between_#{aa}_and_#{res}
          END
        end
      end


      %w(sugar phosphate).each do |moiety|
        class_eval <<-END
          def total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}_#{moiety}
            AminoAcids::Residues::STANDARD.map(&:downcase).sum { |a|
              send("observed_frequency_of_#{int}_between_\#{a}_and_#{na}_#{moiety}")
            }
          end
          memoize :total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}_#{moiety}
        END

        AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa|
          class_eval <<-END
            def observed_frequency_of_#{int}_between_#{aa}_and_#{na}_#{moiety}
              #{na}_interfaces.sum { |i| i.frequency_of_#{int}_between_#{aa}_and_#{moiety} }
            end
            memoize :observed_frequency_of_#{int}_between_#{aa}_and_#{na}_#{moiety}

            def expected_frequency_of_#{int}_between_#{aa}_and_#{na}_#{moiety}
              result =  total_observed_frequency_of_#{int}_between_#{aa}_and_#{na}.to_f *
                        total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}_#{moiety}.to_f /
                        total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}.to_f
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
end # class ScopDomain
