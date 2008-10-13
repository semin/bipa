class String
  def nil_if_blank
    self.blank? ? nil : self
  end
end
