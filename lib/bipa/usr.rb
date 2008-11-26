module Bipa
  module Usr

    ShapeDescriptors = %w(
      ctd_mean
      ctd_variance
      ctd_skewness
      cst_mean
      cst_variance
      cst_skewness
      fct_mean
      fct_variance
      fct_skewness
      ftf_mean
      ftf_variance
      ftf_skewness
    )

    def atom_vectors
      @atom_vectors ||= get_atom_vectors
    end

    def get_atom_vectors
      # filter hydogen atoms
      atoms.select { |a1| a1.atom_name !~ /^H/ }.map { |a2| Vector[a2.x, a2.y, a2.z] }
    end

    # the molecular centroid (ctd)
    def ctd
      @ctd ||= calculate_ctd
    end

    def calculate_ctd
      atom_vectors.inject(Vector[0, 0, 0]) { |s, v| s + v } * (1.0 / atom_vectors.size)
    end

    # the closest atom to ctd (cst)
    def cst
      @cst ||= find_vector_to ctd, :closest
    end

    # the farthest atom to ctd (fct)
    def fct
      @fct ||= find_vector_to ctd, :farthest
    end

    # the farthest atom to fct (ftf)
    def ftf
      @ftf ||= find_vector_to fct, :farthest
    end

    def find_vector_to(target_vector, condition)
      temp_vector   = nil
      temp_distance = nil

      atom_vectors.each do |atom_vector|
        next if atom_vector == target_vector
        distance = (atom_vector - target_vector).r
        case condition
        when :closest
          if (temp_distance.nil?) || (distance < temp_distance)
            temp_vector   = atom_vector
            temp_distance = distance
          end
        when :farthest
          if (temp_distance.nil?) || (distance > temp_distance)
            temp_vector   = atom_vector
            temp_distance = distance
          end
        else
          raise "Unknown condition: #{condition}"
        end
      end
      temp_vector
    end

    def ctd_distance_distribution
      @ctd_distance_distribution ||= calculate_distance_distribution_to ctd
    end

    def cst_distance_distribution
      @cst_distance_distribution ||= calculate_distance_distribution_to cst
    end

    def fct_distance_distribution
      @fct_distance_distribution ||= calculate_distance_distribution_to fct
    end

    def ftf_distance_distribution
      @ftf_distance_distribution ||= calculate_distance_distribution_to ftf
    end

    def calculate_distance_distribution_to(target_vector)
      atom_vectors.map { |atom_vector| (atom_vector - target_vector).r }
    end

    def shape_descriptors
      @shape_descriptors ||= calculate_shape_descriptors
    end

    def calculate_shape_descriptors
      Vector[
        ctd_distance_distribution.to_stats_array.mean,
        ctd_distance_distribution.to_stats_array.variance,
        ctd_distance_distribution.to_stats_array.skewness,
        cst_distance_distribution.to_stats_array.mean,
        cst_distance_distribution.to_stats_array.variance,
        cst_distance_distribution.to_stats_array.skewness,
        fct_distance_distribution.to_stats_array.mean,
        fct_distance_distribution.to_stats_array.variance,
        fct_distance_distribution.to_stats_array.skewness,
        ftf_distance_distribution.to_stats_array.mean,
        ftf_distance_distribution.to_stats_array.variance,
        ftf_distance_distribution.to_stats_array.skewness
      ]
    end

    def shape_similarity_with(other)
      sa = self.shape_descriptors
      sb = other.shape_descriptors
      1.0 / (1 + (sa.manhattan_distance_to(sb) / 12.0))
    end

  end
end
