class String

  def nil_if_blank
    self.blank? ? nil : self
  end

  def html_word_wrap(col_width=80)
    self.gsub!( /(\S{#{col_width}})(?=\S)/, '\1 ' )
    self.gsub!( /(.{1,#{col_width}})(?:\s+|$)/, "\\1<br />" )
    self
  end

  def shorten(word_limit = 20)
    words = self.split(/\s/)
    if words.size >= word_limit
      words[0,(word_limit-1)].join(" ") + '...'
    else
      self
    end
  end
end
