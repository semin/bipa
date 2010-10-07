class Sequence < ActiveRecord::Base

  attr_accessor :weight

  belongs_to  :alignment

  belongs_to  :domain,
              :class_name => "ScopDomain",
              :foreign_key  => "scop_id"

  belongs_to  :chain

  has_many  :positions,
            :order  => "number"

  delegate  :resolution, :to => :domain


  def amino_acids
    positions.map(&:residue_name)
  end

  def sequence
    amino_acids.join
  end

  def formatted_sequence
    positions.map(&:formatted_residue_name).join
  end

  def pid(other)
    aas1  = amino_acids
    aas2  = other.amino_acids
    cols  = aas1.zip(aas2)
    gap   = '-'
    align = 0.0 # no. of aligned columns
    ident = 0.0 # no. of identical columns
    intgp = 0.0 # no. of internal gaps
    cols.each do |col|
      if (col[0] != gap) && (col[1] != gap)
        align += 1
        if col[0] == col[1]
          ident += 1
        end
      elsif (((col[0] == gap) && (col[1] != gap)) ||
             ((col[0] != gap) && (col[1] == gap)))
        intgp += 1
      end
    end
    Float(ident) / (align + intgp)
  end

  def to_flatfile(options={})
    opts = {
      :os     => STDOUT,
      :type   => :pir,
      :width  => 70
    }.merge!(options)

    out = opts[:os].is_a?(String) ? File.open(opts[:os], 'w') : opts[:os]

    out.puts opts[:type] == :pir ? ">P1;#{@code}" : ">#{@code}"
    out.puts "sequence" if opts[:type] == :pir

    aas = amino_acids << '*'
    out.puts aas.map_with_index { |a, ai|
      a + (ai > 0 && (ai+1) % opts[:width] == 0 ? "\n" : '')
    }.join('').chomp

    out.close if [File, String].include?(out.class)
  end
end
