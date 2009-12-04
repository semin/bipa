module PathnameExtensions

  def to_str
    to_s
  end

end

Pathname.send(:include, PathnameExtensions)
