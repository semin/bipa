module ArrayExtensions

  def to_stats_array
    Bipa::StatsArray.new(self)
  end

end

Array.send(:include, ArrayExtensions)
