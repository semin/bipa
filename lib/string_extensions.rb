class String

  def nil_if_blank
    self.blank? ? nil : self
  end

  def html_word_wrap(col_width=80)
    self.gsub!( /(\S{#{col_width}})(?=\S)/, '\1 ' )
    self.gsub!( /(.{1,#{col_width}})(?:\s+|$)/, "\\1<br />" )
    self
  end
end
