module VectorExtensions
  def manhattan_distance_to(other)
    (self-other).map {|e| e.abs}.to_a.inject(0) {|s, t| s + t}
  end
end

Vector.send :include, VectorExtensions
