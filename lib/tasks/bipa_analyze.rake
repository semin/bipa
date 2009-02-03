namespace :bipa do
  namespace :analyze do

    desc "Get a ROC table"
    task :roc => [:environment] do
      fam_std_fps     = StdFugueHit.fam_fp.sort_by(&:zscore).reverse
      fam_na_fps      = NaFugueHit.fam_fp.sort_by(&:zscore).reverse
      supfam_std_fps  = StdFugueHit.supfam_fp.sort_by(&:zscore).reverse
      supfam_na_fps   = NaFugueHit.supfam_fp.sort_by(&:zscore).reverse

      fam_std_fps.each_with_index do |fam_std_fp, i|
        if fam_na_fps[i] && supfam_std_fps[i] && supfam_na_fps[i]
          fam_std_tps     = StdFugueHit.fam_tp.zscore_gt(fam_std_fp.zscore)
          fam_na_tps      = NaFugueHit.fam_tp.zscore_gt(fam_na_fps[i].zscore)
          supfam_std_tps  = StdFugueHit.supfam_tp.zscore_gt(supfam_std_fps[i].zscore)
          supfam_na_tps   = NaFugueHit.supfam_tp.zscore_gt(supfam_na_fps[i].zscore)

          puts "#{i}\t#{fam_std_tps.count}\t#{fam_na_tps.count}\t#{supfam_std_tps.count}\t#{supfam_na_tps.count}"
        else
          break
        end
      end
    end


    desc "Check Alignment Accuracy"
    task :alignment_accuracy => [:environment] do
      (0..90).step(20) do |x|
        rfs = ReferenceAlignment.pid_range(4, x, x+10).all
        print "#{rfs.sum { |rf| rf.test_needle_alignment.sp }     / rfs.count}\t"
        print "#{rfs.sum { |rf| rf.test_clustalw_alignment.sp }   / rfs.count}\t"
        print "#{rfs.sum { |rf| rf.test_std_fugue_alignment.sp }  / rfs.count}\t"
        puts  "#{rfs.sum { |rf| rf.test_na_fugue_alignment.sp }   / rfs.count}"
      end
    end


    desc "Get nsSNP statistics over Domain-DNA/RNA interfaces"
    task :nssnp_stats => [:environment] do
      puts "DOM_SID DOM_RES_CNT DOM_NSSNP_CNT CORE_RES_CNT CORE_NSSNP_CNT SURF_RES_CNT SURF_NSSNP_CNT INTF_RES_CNT INTF_NSSNP_MAPPED_RES_CNT"

      DomainDnaInterface.in_residues_count_range(4, 1000).find_all_in_chunks do |intf|
        dom = intf.domain
        if dom.variation_mapped_residues.size > 0
          puts [dom.sid,
                dom.residues.count,
                dom.nssnp_mapped_residues.count,
                dom.buried_residues.count,
                dom.buried_residues.select { |r| r.nssnps.size > 0 }.andand.count,
                dom.surface_residues.count,
                dom.surface_residues.select { |r| r.nssnps.size > 0 }.andand.count,
                intf.residues.count,
                intf.nssnp_mapped_residues.count].join(" ")
        end
      end
    end

  end
end
