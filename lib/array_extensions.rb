module ArrayExtensions

  def to_stats_array
    Bipa::StatsArray.new(self)
  end

  def to_pathnames
    self.map { |x| Pathname.new(x) }
  end

  def chunk(pieces=2)
    len = self.length;
    mid = (len/pieces)
    chunks = []
    start = 0
    1.upto(pieces) do |i|
      last = start+mid
      last = last-1 unless len%pieces >= i
      chunks << self[start..last] || []
      start = last+1
    end
    chunks
  end

end

Array.send(:include, ArrayExtensions)
