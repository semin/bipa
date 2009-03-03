module MathExtensions

  def Math::float_equal(a, b)
    c = a - b
    c *= -1.0 if c < 0
    c < 0.000000001	# TODO: how should we pick epsilon?
  end

  def Math::cbrt(a)
    if (a < 0)
      -1 * a.abs ** (1.0/3)
    else
      a ** (1.0/3)
    end
  end

end

Math.send :include, MathExtensions
