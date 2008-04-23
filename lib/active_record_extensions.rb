module FindAllInChunks

  def find_all_in_chunks(query = Hash.new, &iterator)
    1.upto(1.0/0.0) do |i|
      records = paginate({:page => i, :per_page => 50}.merge(query))
      records.each(&iterator)
      break unless records.next_page
    end
  end

end

ActiveRecord::Base.extend(FindAllInChunks)
