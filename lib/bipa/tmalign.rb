module Bipa
  class Tmalign

    def self.calculate_tmscore(pdb1, pdb2, tmalign="TMalign")
      res = `#{tmalign} #{pdb1} #{pdb2} -a`
      res.split("\n").each do |line|
        if line =~ /^Aligned\s+length=\s*(\S+),\s*RMSD=\s*(\S+),\s*TM-score=\s*(\S+),\s+ID=\s*(\S+)/
          length  = $1.to_i
          rmsd    = $2.to_f
          tmscore = $3.to_f
          id      = $4.to_f
          return tmscore
        end
      end
      raise "!!! Something wrong with TMaligning #{pdb1} and #{pdb2}"
    end

    def self.single_linkage_clustering(clusters, tm_score=0.5)
      begin
        continue = false
        0.upto(clusters.size - 2) do |i|
          indexes = []
          (i + 1).upto(clusters.size - 1) do |j|
            found = false
            clusters[i].each do |pdb1|
              clusters[j].each do |pdb2|
                if calculate_tmscore(pdb1, pdb2) >= tm_score
                  indexes << j
                  found = true
                  break
                end
              end
              break if found
            end
          end

          unless indexes.empty?
            continue = true
            group = clusters[i]
            indexes.each do |k|
              group = group.concat(clusters[k])
              clusters[k] = nil
            end
            clusters[i] = group
            clusters.compact!
          end
        end
      end while(continue)
      clusters
    end

  end
end
