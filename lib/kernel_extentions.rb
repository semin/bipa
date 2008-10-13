module Kernel

  private

  def this_method
   caller[0] =~ /`([^']*)'/ and $1
  end
end

