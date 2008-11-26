module NumericExtentions

  def to_similarity
    1.0 / Math::E ** Math::log(self + 1.0)
  end

end

Numeric.send(:include, NumericExtentions)
