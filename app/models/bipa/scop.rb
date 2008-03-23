class Bipa::Scop < ActiveRecord::Base

  include Bipa::Constants

  acts_as_nested_set

  is_indexed :fields => ["sccs", "sunid", "pdb_code", "description", "registered"]

  scope_out :registered

  def self.factory_create!(opt={})
    case opt[:stype]
    when 'root' then Bipa::ScopRoot.create!(opt)
    when 'cl'   then Bipa::ScopClass.create!(opt)
    when 'cf'   then Bipa::ScopFold.create!(opt)
    when 'sf'   then Bipa::ScopSuperFamily.create!(opt)
    when 'fa'   then Bipa::ScopFamily.create!(opt)
    when 'dm'   then Bipa::ScopProtein.create!(opt)
    when 'sp'   then Bipa::ScopSpecies.create!(opt)
    when 'px'   then Bipa::ScopDomain.create!(opt)
    else; raise "Unknown SCOP hierarchy: #{opt[:stype]}"; end
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

  # Statistical properties
  %w(dna rna).each do |na|
    %w(mean stddev).each do |property|
      define_method "#{property}_#{na}_interface_asa" do
        "%.2f" % send("#{na}_interfaces").map { |i|
          i.asa
        }.to_stats_array.send(property)
      end

      define_method "#{property}_#{na}_interface_hbonds" do
        "%.2f" % send("#{na}_interfaces").map { |i|
          (i.hbonds_as_donor.size + i.hbonds_as_acceptor.size) / i.asa * 100
        }.to_stats_array.send(property)
      end

      define_method "#{property}_#{na}_interface_whbonds" do
        "%.2f" % send("#{na}_interfaces").map { |i|
          i.whbonds.size / i.asa * 100
        }.to_stats_array.send(property)
      end

      define_method "#{property}_#{na}_interface_contacts" do
        "%.2f" % send("#{na}_interfaces").map { |i|
          (i.contacts.size - i.hbonds_as_donor.size - i.hbonds_as_acceptor.size) / i.asa * 100
        }.to_stats_array.send(property)
      end

      define_method "#{property}_#{na}_interface_polarity" do
        "%.2f" % send("#{na}_interfaces").map { |i|
          i.polarity
        }.to_stats_array.send(property)
      end

      AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa|
        define_method "#{property}_#{na}_interface_singlet_propensity_of_#{aa}" do
          "%.2f" % send("#{na}_interfaces").map { |i|
            i.send("singlet_propensity_of_#{aa}")
          }.to_stats_array.send(property)
        end
      end

      Dssp::SSES.map(&:downcase).each do |sse|
        define_method "#{property}_#{na}_interface_sse_propensity_of_#{sse}" do
          "%.2f" % send("#{na}_interfaces").map { |i|
            i.send("sse_propensity_of_#{sse}")
          }.to_stats_array.send(property)
        end
      end
    end
  end


  %w(hbond whbond contact).each do |int|
    %w(dna rna).each do |na|
      na_residues = "Bipa::Constants::NucleicAcids::#{na.camelize}::Residues::STANDARD".constantize.map(&:downcase)

      define_method :"total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}" do
        if instance_variable_defined?("@total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}")
          return instance_variable_get("@total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}")
        else
          result = AminoAcids::Residues::STANDARD.map(&:downcase).sum { |a|
            send("total_observed_frequency_of_#{int}_between_#{a}_and_#{na}")
          }
          instance_variable_set("@total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}", result)
        end
      end

      AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa|
        define_method :"total_observed_frequency_of_#{int}_between_#{aa}_and_#{na}" do
          if instance_variable_defined?("@total_observed_frequency_of_#{int}_between_#{aa}_and_#{na}")
            return instance_variable_get("@total_observed_frequency_of_#{int}_between_#{aa}_and_#{na}")
          else
            result = na_residues.sum { |r|
              send("observed_frequency_of_#{int}_between_#{aa}_and_#{r}")
            } + %w(sugar phosphate).sum { |m|
              send("observed_frequency_of_#{int}_between_#{aa}_and_#{na}_#{m}")
            }
            instance_variable_set("@total_observed_frequency_of_#{int}_between_#{aa}_and_#{na}", result)
          end
        end
      end

      na_residues.each do |res|
        define_method :"total_observed_frequency_of_#{int}_between_amino_acids_and_#{res}" do
          if instance_variable_defined?("@total_observed_frequency_of_#{int}_between_amino_acids_and_#{res}")
            return instance_variable_get("@total_observed_frequency_of_#{int}_between_amino_acids_and_#{res}")
          else
            result = AminoAcids::Residues::STANDARD.map(&:downcase).sum { |r|
              send("observed_frequency_of_#{int}_between_#{r}_and_#{res}")
            }
            instance_variable_set("@total_observed_frequency_of_#{int}_between_amino_acids_and_#{res}", result)
          end
        end

        AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa|
          define_method :"observed_frequency_of_#{int}_between_#{aa}_and_#{res}" do
            if instance_variable_defined?("@observed_frequency_of_#{int}_between_#{aa}_and_#{res}")
              return instance_variable_get("@observed_frequency_of_#{int}_between_#{aa}_and_#{res}")
            else
              result = send("#{na}_interfaces").sum { |i|
                i.send("frequency_of_#{int}_between_#{aa}_and_#{res}")
              }
              instance_variable_set("@observed_frequency_of_#{int}_between_#{aa}_and_#{res}", result)
            end
          end

          define_method :"expected_frequency_of_#{int}_between_#{aa}_and_#{res}" do
            if instance_variable_defined?("@expected_frequency_of_#{int}_between_#{aa}_and_#{res}")
              return instance_variable_get("@expected_frequency_of_#{int}_between_#{aa}_and_#{res}")
            else
              result = (
                send("total_observed_frequency_of_#{int}_between_#{aa}_and_#{na}").to_f *
                send("total_observed_frequency_of_#{int}_between_amino_acids_and_#{res}").to_f /
                send("total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}").to_f
              )
              result.nan? ? 0 : "%.2f" % result
              instance_variable_set("@expected_frequency_of_#{int}_between_#{aa}_and_#{res}", result)
            end
          end
        end
      end


      %w(sugar phosphate).each do |moiety|
        define_method :"total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}_#{moiety}" do
          if instance_variable_defined?("@total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}_#{moiety}")
            return instance_variable_get("@total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}_#{moiety}")
          else
            result = AminoAcids::Residues::STANDARD.map(&:downcase).sum { |a|
              send("observed_frequency_of_#{int}_between_#{a}_and_#{na}_#{moiety}")
            }
            instance_variable_set("@total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}_#{moiety}", result)
          end
        end

        AminoAcids::Residues::STANDARD.map(&:downcase).each do |aa|
          define_method :"observed_frequency_of_#{int}_between_#{aa}_and_#{na}_#{moiety}" do
            if instance_variable_defined?("@observed_frequency_of_#{int}_between_#{aa}_and_#{na}_#{moiety}")
              return instance_variable_get("@observed_frequency_of_#{int}_between_#{aa}_and_#{na}_#{moiety}")
            else
              result = send("#{na}_interfaces").sum { |i|
                i.send("frequency_of_#{int}_between_#{aa}_and_#{moiety}")
              }
              instance_variable_set("@observed_frequency_of_#{int}_between_#{aa}_and_#{na}_#{moiety}", result)
            end
          end

          define_method :"expected_frequency_of_#{int}_between_#{aa}_and_#{na}_#{moiety}" do
            if instance_variable_defined?("@expected_frequency_of_#{int}_between_#{aa}_and_#{na}_#{moiety}")
              return instance_variable_get("@expected_frequency_of_#{int}_between_#{aa}_and_#{na}_#{moiety}")
            else
              result = (
                send("total_observed_frequency_of_#{int}_between_#{aa}_and_#{na}").to_f *
                send("total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}_#{moiety}").to_f /
                send("total_observed_frequency_of_#{int}_between_amino_acids_and_#{na}").to_f
              )
              result.nan? ? 0 : "%.2f" % result
              instance_variable_set("@expected_frequency_of_#{int}_between_#{aa}_and_#{na}_#{moiety}", result)
            end
          end
        end
      end

    end #
  end #
end # class Scop


class Bipa::ScopRoot < Bipa::Scop
end


class Bipa::ScopClass < Bipa::Scop
end


class Bipa::ScopFold < Bipa::Scop
end


class Bipa::ScopSuperFamily < Bipa::Scop
end


class Bipa::ScopFamily < Bipa::Scop

  (10..100).step(10) do |si|
    has_many  :"subfamily#{si}s",
              :class_name   => "Bipa::Subfamily#{si}",
              :foreign_key  => "scop_family_id"
  end
end


class Bipa::ScopProtein < Bipa::Scop
end


class Bipa::ScopSpecies < Bipa::Scop
end


class Bipa::ScopDomain < Bipa::Scop

  include Bipa::Usr
  include Bipa::NucleicAcidBinding
  include Bipa::ComposedOfResidues
  include Bipa::ComposedOfAtoms

  (10..100).step(10) do |si|
    belongs_to  :"subfamily#{si}",
                :class_name   => "Bipa::Subfamiy#{si}",
                :foreign_key  => "subfamily#{si}_id"
  end

  has_many  :dna_interfaces,
            :class_name   => "Bipa::DomainDnaInterface",
            :foreign_key  => 'scop_id'
            
  has_many  :rna_interfaces,
            :class_name   => 'Bipa::DomainRnaInterface',
            :foreign_key  => 'scop_id'
            
  has_many  :residues,
            :class_name   => 'Bipa::AaResidue',
            :foreign_key  => 'scop_id'
            
  has_many  :chains,
            :through      => :residues,
            :uniq         => true
            
  has_many  :atoms,
            :through      => :residues
            
  has_many  :contacts,
            :through      => :atoms
            
  has_many  :contacting_atoms, 
            :through      => :contacts
            
  has_many  :whbonds,
            :through      => :atoms
            
  has_many  :whbonding_atoms,
            :through      => :whbonds
            
  has_many  :hbonds_as_donor,
            :through      => :atoms
            
  has_many  :hbonds_as_acceptor,
            :through      => :atoms
            
  has_many  :hbonding_donors,
            :through      => :hbonds_as_acceptor
            
  has_many  :hbonding_acceptors,
            :through      => :hbonds_as_donor

  # Methods
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
    end # each des
    result
  end

  def resolution
    chains.first.model.structure.resolution
  end

  def calpha_only?
    atoms.map(&:atom_name).uniq == ["CA"]
  end

  def to_pdb
    atoms.sort_by(&:atom_code).inject("") { |p, a| p + a.to_pdb }
  end

  def to_fasta
    residues.sort_by(&:residue_code).map(&:one_letter_code).join
  end

  # Callbacks
  def update_pdb_code
    pdb_code = (stype == 'px' ? description[0..3].upcase : '-')
  end

  def update_unbound_asa
    unbound_asa = atoms.inject(0) { |s, a| a.unbound_asa ? s + a.unbound_asa : s }
  end

  def update_bound_asa
    bound_asa = atoms.inject(0) { |s, a| a.bound_asa ? s + a.bound_asa : s }
  end

  def update_delta_asa
    delta_asa = atoms.inject(0) { |s, a| a.delta_asa ? s + a.delta_asa : s }
  end

end # class ScopDomain
