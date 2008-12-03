class FugueSearchWorker < Workling::Base

  def search(options)
    logger.info ">>> I'm doing something here #{File.expand_path(__FILE__)}"

    @fugue_search = FugueSearch.find(options[:id])

    logger.info ">>> Running FUGUE search for FugueSearch, #{fugue_search.id}: start"

    @fugue_search.started_at = Time.now


#    File.open(File.join(File.expand_path(__FILE__), "/../../public/fugue", "fugue_search-#{@fugue_search.id}.fa"), "w") do |file|
#      if @fugue_search.sequence.match(/^>/)
#        ff = Bio::FlatFile.auto(StringIO.new(@fugue_search.sequence))
#        ff.each_entry do |ent|
#          file.puts ">#{ent.entry_id}"
#          file.puts ent.seq
#        end
#      else
#        file.puts ">#{@fugue_search.name.empty? ? 'Your sequence' : @fugue_search.name}"
#        file.puts @fugue_search.sequence
#      end
#    end

    @fugue_search.finished_at = Time.now
    @fugue_search.save!

    logger.info ">>> Running FUGUE search for FugueSearch, #{fugue_search.id}: finish"
  end

end
