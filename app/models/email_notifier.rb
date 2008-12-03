class EmailNotifier < ActionMailer::Base

  def notify(fugue_search)
    recipients fugue_search.email
    from       "semin@cryst.bioc.cam.ac.uk"
    subject    "FUGUE-na search result from BIPA"
    body       :fugue_search => fugue_search
  end
end
