class FugueSearch < ActiveRecord::Base

  validates_presence_of :email, :sequence
  validate :valid_email?

  before_save :sanitize_sequence

  def valid_email?
    TMail::Address.parse(email)
  rescue
    errors.add_to_base("Must be a valid email")
  end

  def sanitize_sequence
    sequence.upcase!
  end
end


class FugueSearchDna < FugueSearch
end


class FugueSearchRna < FugueSearch
end
