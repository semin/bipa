class FugueSearch < ActiveRecord::Base

  validates_presence_of :email, :sequence
  validate :valid_email?

  def start
    puts "FUGUE search st start!"
  end

  def valid_email?
      TMail::Address.parse(email)
  rescue
      errors.add_to_base("Must be a valid email")
  end

end


class FugueSearchDna < FugueSearch
end


class FugueSearchRna < FugueSearch
end
