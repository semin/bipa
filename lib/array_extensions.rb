module ArrayExtensions
  def to_stats_array
    BIPA::StatsArray.new(self)
  end
end

Array.send :include, ArrayExtensions
