class FugueHit < ActiveRecord::Base

  belongs_to :profile

  belongs_to :scop

  named_scope :fam_tp, :conditions => { :fam_tp => true }
  named_scope :fam_fp, :conditions => { :fam_fp => true }
  named_scope :fam_tn, :conditions => { :fam_tn => true }
  named_scope :fam_fn, :conditions => { :fam_fn => true }

  named_scope :supfam_tp, :conditions => { :supfam_tp => true }
  named_scope :supfam_fp, :conditions => { :supfam_fp => true }
  named_scope :supfam_tn, :conditions => { :supfam_tn => true }
  named_scope :supfam_fn, :conditions => { :supfam_fn => true }

  named_scope :zscore_gt, lambda { |*args|
    { :conditions => ["zscore > ?", args[0]] }
  }

end

class StdFugueHit < FugueHit
end

class NaFugueHit < FugueHit
end
