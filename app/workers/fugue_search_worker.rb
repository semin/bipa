require "rubygems"
require "fileutils"
require "tmpdir"
require "bio"

include FileUtils

class FugueSearchWorker < Workling::Base

  def search(options)
    @fugue_search = FugueSearch.find(options[:id])

    logger.info ">>> Running FUGUE search for FugueSearch, #{@fugue_search.id}: start"

    @fugue_search.started_at = Time.now

    # a name for the fasta file to store user sequence and run fugueseq
    fasta_file = File.join(Dir::tmpdir, "fugue_na_search-#{@fugue_search.id}.fa")

    # Create fasta file for user sequence
    File.open(fasta_file, "w") do |file|
      if @fugue_search.definition
        file.puts ">#{@fugue_search.definition}"
      elsif @fugue_search.name
        file.puts ">#{@fugue_search.name}"
      else
        file.puts ">Your sequence"
      end
      file.puts @fugue_search.sequence
    end

    # Run fugueseq with the fasta file created above
    fugueseq  =  "/BiO/Install/ORCHESTRAR/Package_1.8b/Orchestrar_source/bin/fugueseq"
    prflist   =  @fugue_search.is_a?(FugueSearchDna) ?
                "/BiO/Research/BIPA/bipa/public/essts/nr80/dna/64/FUGLIST" :
                "/BiO/Research/BIPA/bipa/public/essts/nr80/rna/64/FUGLIST"

    if File.exist? fasta_file
      cwd = pwd
      cd Dir::tmpdir
      @result = `#{fugueseq} -seq #{File.basename(fasta_file)} -list #{prflist} -toprank #{@fugue_search.toprank}`
      @fugue_search.result = (@result ? @result : "We tried to run FUGUE, but something is wrong...")
      cd cwd
    else
      @fugue_search.result = "Cannot create a fasta file for your query sequence"
    end

    # log and save fugue_search object
    @fugue_search.finished_at = Time.now
    @fugue_search.save!

    # send an email to user
    EmailNotifier.deliver_notify(@fugue_search)

    logger.info ">>> Running FUGUE search for FugueSearch, #{@fugue_search.id}: finish"
  end

end
