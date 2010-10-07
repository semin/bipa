namespace :bipa do
  namespace :test do

    desc "Count conserved residue pairs among alignments"
    task :residue_pairs => [:environment] do

      total     = 0
      cons      = 0
      families  = ScopFamily.registered.find(:all)

      families.each do |family|
        next if family.rep90_alignment.nil? || family.rep100_alignment.nil?

        rsp100  = family.rep100_alignment.residue_pairs
        rsp90   = family.rep90_alignment.residue_pairs
        total   += rsp90.size
        count   = rsp90.inject(0) { |s, e| rsp100.include?(e) ? s + 1 : s }
        cons    += count

        puts "#{count} out of #{rsp90.size} (#{(100 * count.to_f / rsp90.size).round} %) residue pairs of rep90 alignments are conserved in rep100 alignments of SCOP Family, #{family.sunid}: #{family.description}"
      end

      puts "Total, #{cons} out of #{total} (#{(100 * cons.to_f / total).round} %) residue pairs of rep90 alignments are conserved in rep100 alignments"
    end

  end
end
