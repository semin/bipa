module NumericExtentions

  def to_similarity
    1.0 / Math::E ** Math::log(self + 1.0)
  end

  inline do |builder|
    builder.include '<math.h>'
    builder.c <<-C_CODE
    double to_similarity_in_c() {
      return 1.0 / exp(log(NUM2DBL(self) + 1.0));
    }
    C_CODE
  end

end

Numeric.send(:include, NumericExtentions)
