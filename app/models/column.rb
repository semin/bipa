class Column < ActiveRecord::Base

  @@aas = %w[A R N D B C E Q Z G H I L K M F P S T W Y V]

  belongs_to :alignment

  has_many  :positions

  has_many  :profile_columns

  def calculate_entropy
    aa_cnt = Hash.new(0)
    aa_prb = Hash.new(0.0)

    positions.each do |pos|
      if pos.residue_name = 'Y'
        aa_cnt['C'] += 1
      elsif pos.residue_name = 'X'
        next
      else
        aa_cnt[pos.residue_name] += 1
      end
    end

    aa_cnt.keys.each do |aa|
      aa_prb[aa] = aa_cnt[aa] / positions.count.to_f
    end

    entropy = 0.0

    aa_prb.values.each do |prb|
      entropy += prb * Math::log(prb) if prb != 0
    end

    (-1) * entropy
  end

end
