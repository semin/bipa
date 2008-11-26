class FugueSearchWorker < Workling::Base

  def search(options)
    fugue_search = FugueSearch.find(options[:id])

    logger.info ">>> Running FUGUE search for FugueSearch, #{fugue_search.id}: start"

    fugue_search.started_at = Time.now
    sleep 10
    fugue_search.finished_at = Time.now
    fugue_search.save!

    logger.info ">>> Running FUGUE search for FugueSearch, #{fugue_search.id}: finish"
  end

end
