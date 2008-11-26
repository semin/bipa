class FugueSearchWorker < Workling::Base
  def search(options)
    fugue_search = FugueSearch.find(options[:id])
    logger.info ">>> Running FUGUE search for FugueSearch, #{fugue_search.id}: start"
    fugue_search.start
    logger.info ">>> Running FUGUE search for FugueSearch, #{fugue_search.id}: finish"
  end
end
