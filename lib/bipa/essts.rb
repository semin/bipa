module Bipa

  require "narray"

  class Esst

    attr_reader :matrix

    def initialize(env_name, col_names, row_names, rows)
      @env_name   = env_name
      @col_names  = col_names
      @row_names  = row_names
      @matrix     = NMatrix[*rows]
    end

    def column(col_name)
      col_index = @col_names.index(col_name)
      if col_index.nil?
        raise "Unknown residue type: #{col_name}"
      else
        NVector[*(0...@matrix.shape[1]).map { |row_i| @matrix[col_index, row_i] }]
      end
    end
  end

  class Essts

    attr_reader :essts

    def initialize(file)
      aas     = 'ACDEFGHIKLMNPQRSTVWY'.split('')
      env     = nil
      rows    = []
      @essts  = []

      file_str = File.exists?(file) ? IO.read(file) : file
      file_str.split("\n").each_with_index do |line, i|
        line.chomp!
        if line =~ /^#/ or line.blank?
          next
        elsif line =~ /^>(\S+)\s+(\d+)/
          if !rows.empty?
            @essts << Esst.new(env, aas, aas, rows)
            rows.clear
          end
          if $1 == 'Total'
            break
          end
          env == $1
        elsif line =~ /^\S\s+(.*)$/
          rows << $1.strip.split(/\s+/).map(&:to_f)
        else
          raise "Unknown style of line, #{i + 1}: #{line}"
        end
      end
    end

  end
end
