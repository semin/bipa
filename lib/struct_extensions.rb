class Struct
  def to_hash
    hash = Hash.new
    self.each_pair do |sym, obj|
      hash[sym] = obj
    end
    hash
  end
end


