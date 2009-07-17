class Alignment < ActiveRecord::Base

  include Bio::Alignment::EnumerableExtension

  has_many  :sequences,
            :order      => "id",
            :dependent  => :delete_all

  has_many  :columns,
            :order      => "number",
            :dependent  => :delete_all

  has_many  :reference_alignments

  has_one   :profile

  def ruler_with_margin(margin = 9)
    "&nbsp;" * margin + (1..columns.size).map do |i|
      case
      when i <= 10
        i % 10 == 0 ? i : "&nbsp;"
      when i > 10 && i < 100
        if i % 10 == 0 then i
        elsif i % 10 == 1 then ""
        else; "&nbsp;"; end
      when i >= 100 && i < 1000
        if i % 10 == 0 then i
        elsif i % 10 == 1 || i % 10 == 2 then ""
        else; "&nbsp;"; end
      end
    end.join
  end

  def identity
    type.match(/\d+/)[1] || "All"
  end

  def to_fasta
    sequences.each do |seq|
      header = seq.domain ? seq.domain.sid : seq.chain.fasta_header
      puts ">#{header}"
      puts seq.positions.map(&:residue_name).join
    end
  end

  def to_pir
    raise "Not implemented yet!"
  end

  def residue_pairs
    pairs = []

    0.upto(length - 1) do |pos|
      0.upto(sequences.length - 2) do |seq1|
        col1 = sequences[seq1].positions[pos]
        next if col1.residue.nil?

        (seq1 + 1).upto(sequences.length - 1) do |seq2|
          col2 = sequences[seq2].positions[pos]
          next if col2.residue.nil?
          pairs << Set.new([col1.residue, col2.residue])
        end
      end
    end
    pairs
  end

  def length
    sequences.first.positions.length
  end

  def sequences_with_max_resolution(resolution)
    resolution = 999.0 if resolution == "all"
    sequences.select { |s| s.resolution < resolution.to_f }
  end

  # To use Bio::Alignment of BioRuby
  def each_seq
    sequences.each { |s| yield s.positions.map(&:residue_name).join }
  end
end


class SubfamilyAlignment < Alignment

  belongs_to  :subfamily

end


%w[dna rna].each do |na|
  eval <<-EVAL
  class Full#{na.capitalize}BindingFamilyAlignment < Alignment

    belongs_to  :family,
                :class_name   => "ScopFamily",
                :foreign_key  => "scop_id"
  end
  EVAL

  configatron.rep_pids.each do |pid|
    eval <<-EVAL
    class Rep#{pid}#{na.capitalize}BindingFamilyAlignment < Alignment

      belongs_to  :family,
                  :class_name   => "ScopFamily",
                  :foreign_key  => "scop_id"
    end
    EVAL
  end
end
