module MathExtensions
  
  def Math::float_equal(a, b)
    c = a - b
    c *= -1.0 if c < 0
    c < 0.000000001	# TODO: how should we pick epsilon?
  end
  
end

Math.send :include, MathExtensions
