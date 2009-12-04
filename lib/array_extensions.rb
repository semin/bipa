module ArrayExtensions

  def to_stats_array
    Bipa::StatsArray.new(self)
  end

  def to_pathnames
    self.map { |x| Pathname.new(x) }
  end

end

Array.send(:include, ArrayExtensions)
