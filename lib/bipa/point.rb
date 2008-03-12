module BIPA
  class Point
    require 'rubygems'
    require 'inline'
    
    attr_reader :x, :y, :z, :serial, :type

    def initialize(x, y, z, serial = nil, type = nil)
      @x = x
      @y = y
      @z = z
      @xyz = [@x, @y, @z]
      @serial = serial
      @type = type
    end

    def size
      @xyz.size
    end

    def [](index)
      @xyz[index]
    end

    def -(other)
      self.c_distance(self.x, self.y, self.z, other.x, other.y, other.z)
    end

    # def c_distance
    inline do |builder|
      builder.include '<math.h>'
      builder.c '
          double c_distance(double sx, double sy, double sz, 
                            double ox, double oy, double oz) {
            return  sqrt( pow(sx - ox, 2) + 
                          pow(sy - oy, 2) + 
                          pow(sz - oz, 2) );
          }'
    end

    def to_s
      "#{'Point'}:x=#{x}:y=#{y}:z=#{z}:serial=#{serial}:type=#{type}"
    end
  end
end
