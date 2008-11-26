module Bipa
  class StatsArray < Array

    def count
      size
    end

    def sum
      inject(0) { |sum, x| sum + x }
    end

    def mean
      return 0.0 if self.size == 0
      sum.to_f / self.size
    end
    alias :arithmetic_mean :mean

    def median
      return 0 if self.size == 0
      tmp = sort
      mid = tmp.size / 2
      if (tmp.size % 2) == 0
        (tmp[mid-1] + tmp[mid]).to_f / 2
      else
        tmp[mid]
      end
    end

    # The sum of the squared deviations from the mean.
    def summed_sqdevs
      return 0 if count < 2
      m = mean
      map {|x| (x - m) ** 2}.sum
    end

    # Variance of the sample.
    def variance
      # Variance of 0 or 1 elements is 0.0
      return 0.0 if count < 2
      summed_sqdevs / (count - 1)
    end

    # Variance of a population.
    def pvariance
      # Variance of 0 or 1 elements is 0.0
      return 0.0 if count < 2
      summed_sqdevs / count
    end

    # Standard deviation of a sample.
    def stddev
      Math::sqrt(variance)
    end

    # Standard deviation of a population.
    def pstddev
      Math::sqrt(pvariance)
    end

    # Calculates the standard error of this sample.
    def stderr
      return 0.0 if count < 2
      stddev/Math::sqrt(size)
    end

    # Calculates the relative mean difference of this sample.
    # Makes use of the fact that the Gini Coefficient is half the RMD.
    def relative_mean_difference
      return 0.0 if Math::float_equal(mean,0.0)
      gini_coefficient * 2
    end
    alias :rmd :relative_mean_difference

    # The average absolute difference of two independent values drawn from
    # the sample. Equal to the RMD * the mean.
    def mean_difference
      relative_mean_difference * mean
    end
    alias :absolute_mean_difference :mean_difference
    alias :md :mean_difference

    # One of the Pearson skewness measures of this sample.
    def pearson_skewness2
      3*(mean-median)/stddev
    end

    # The skewness of this sample.
    def skewness
      # fail "Buggy"
      return 0.0 if count < 2
      m = mean
      s = inject(0) { |sum,xi| sum+(xi-m)**3 }
      s.to_f/(count*variance**(3/2))
    end

    # The kurtosis of this sample.
    def kurtosis
      fail "Buggy"
      return 0.0 if count < 2
      m = mean
      s = 0
      each { |xi| s += (xi-m)**4 }
      (s.to_f/((count-1)*variance**2))-3
    end

    # Calculates the Theil index (a statistic used to measure economic
    # inequality). http://en.wikipedia.org/wiki/Theil_index
    # TI = \sum_{i=1}^N \frac{x_i}{\sum_{j=1}^N x_j} ln \frac{x_i}{\bar{x}}
    def theil_index
      return -1 if count <= 0 or any? { |x| x < 0 }
      return 0 if count < 2 or all? { |x| Math::float_equal(x,0) }
      m = mean
      s = sum.to_f
      inject(0) do |theil,xi|
        theil + ((xi > 0) ? (Math::log(xi.to_f/m) * xi.to_f/s) : 0.0)
      end
    end

    # Closely related to the Theil index and easily expressible in terms of it.
    # http://en.wikipedia.org/wiki/Atkinson_index
    # AI = 1-e^{theil_index}
    def atkinson_index
      t = theil_index
      (t < 0) ? -1 : 1-Math::E**(-t)
    end

    # Calculates the Gini Coefficient (a measure of inequality of a distribution
    # based on the area between the Lorenz curve and the uniform curve).
    # http://en.wikipedia.org/wiki/Gini_coefficient
    # GC = \frac{1}{N} \left ( N+1-2\frac{\sum_{i=1}^N (N+1-i)y_i}{\sum_{i=1}^N y_i} \right )
    def gini_coefficient2
      return -1 if count <= 0 or any? { |x| x < 0 }
      return 0 if count < 2 or all? { |x| Math::float_equal(x,0) }
      s = 0
      sort.each_with_index { |yi,i| s += (size - i)*yi }
      (size+1-2*(s.to_f/sum.to_f)).to_f/size.to_f
    end

    # Slightly cleaner way of calculating the Gini Coefficient.  Any quicker?
    # GC = \frac{\sum_{i=1}^N (2i-N-1)x_i}{N^2-\bar{x}}
    def gini_coefficient
      return -1 if count <= 0 or any? { |x| x < 0 }
      return 0 if count < 2 or all? { |x| Math::float_equal(x,0) }
      s = 0
      sort.each_with_index { |li,i| s += (2*i+1-size)*li }
      s.to_f/(size**2*mean).to_f
    end

    # The KL-divergence from this array to that of q.
    # NB: You will possibly want to sort both P and Q before calling this
    # depending on what you're actually trying to measure.
    # http://en.wikipedia.org/wiki/Kullback-Leibler_divergence
    def kullback_leibler_divergence(q)
      fail "Buggy."
      fail "Cannot compare differently sized arrays." unless size = q.size
      kld = 0
      each_with_index { |pi,i| kld += pi*Math::log(pi.to_f/q[i].to_f) }
      kld
    end

    # Returns the Cumulative Density Function of this sample (normalised to a fraction of 1.0).
    def cdf(normalised = 1.0)
      s = sum.to_f
      sort.inject([0.0]) { |c,d| c << c[-1] + normalised*d.to_f/s }
    end

  end
end
