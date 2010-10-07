class Alignment < ActiveRecord::Base

  include Bio::Alignment::EnumerableExtension

  has_many  :sequences,
            :order      => "id",
            :dependent  => :delete_all

  has_many  :columns,
            :order      => "number",
            :dependent  => :delete_all

  #has_many  :reference_alignments

  #has_one   :profile

  def contains?(obj)
    if obj.kind_of? ScopDomain
      sequences.map(&:domain).include?(obj)
    elsif obj.kind_of? Chain
      sequences.map(&:chain).include?(obj)
    else
      false
    end
  end

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

  def calculate_equal_weights
    sequences.each { |s| s.weight = 1.0 / seqs.size }
  end

  def calculate_va_weights
    tot   = 0.0
    dists = Array.new(sequences.size)

    # calculate all by all percentage dissimilarity
    (0...(sequences.size-1)).each do |i|
      dists[i] = Array.new(sequences.size)
      ((i+1)...sequences.size).each do |j|
        d = 1 - sequences[i].pid(sequences[j])
        tot += d
        dists[i][j] = d
      end
    end

    # calculate VA weights
    (0...sequences.size).each do |i|
      sum = 0.0
      (0...sequences.size).each do |j|
        if (i < j)
          sum += dists[i][j]
        elsif (i > j)
          sum += dists[j][i]
        end
      end
      w = (sum / 2.0) / tot
      sequences[i].weight = w
    end
  end

  def calculate_blosum_weights_rb(weight=0.6)
    clusters = sequences.map { |s| [s] }
    begin
      continue = false
      0.upto(clusters.size-2) do |i|
        indexes = []
        (i+1).upto(clusters.size-1) do |j|
          found = false
          clusters[i].each do |s1|
            clusters[j].each do |s2|
              if s1.pid(s2) >= weight
                indexes << j
                found = true
                break
              end
            end
            break if found
          end
        end
        unless indexes.empty?
          continue  = true
          group     = clusters[i]
          indexes.each do |k|
            group       = group.concat(clusters[k])
            clusters[k] = nil
          end
          clusters[i] = group
          clusters.compact!
        end
      end
    end while(continue)

    seq_cnt = Float(sequences.size)

    clusters.each do |cluster|
      cluster.each do |seq|
        weight = cluster.size / seq_cnt
        seq.weight = weight
      end
    end
  end

end


class SubfamilyAlignment < Alignment

  belongs_to :subfamily

end


%w[dna rna].each do |na|
  eval <<-EVAL
  class #{na.capitalize}BindingScopFamilyAlignment < Alignment

    belongs_to  :family,
                :class_name   => "ScopFamily",
                :foreign_key  => "scop_id"

  end

  class #{na.capitalize}BindingTmalignFamilyAlignment < Alignment

    belongs_to  :tmalign_family

  end
  EVAL
end
