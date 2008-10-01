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
    end

  end
end
