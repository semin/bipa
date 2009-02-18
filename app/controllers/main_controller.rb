class MainController < ApplicationController

  #caches_page :home, :contact

  def home
    @structure    = Structure.latest.first
    @latest_news  = News.order('date desc').limit(5)

    %w[dna rna].each do |na|
      eval <<-RUBY_CODE
        @#{na}_interfaces ||= ScopDomain.rp80_#{na}.map { |d| d.#{na}_interfaces }.flatten.compact
      RUBY_CODE

      %w[asa polarity hbonds_count whbonds_count vdw_contacts_count].each do |property|
        eval <<-RUBY_CODE
          @mean_#{na}_interface_#{property} ||= @#{na}_interfaces.map(&:#{property}).to_stats_array.mean
          @stddev_#{na}_interface_#{property} ||= @#{na}_interfaces.map(&:#{property}).to_stats_array.stddev
        RUBY_CODE
      end
    end

    respond_to do |format|
      format.html
    end
  end

  def contact
    respond_to do |format|
      format.html
    end
  end

  def news
    @news = News.order('date desc')
  end

  def search
    case params[:search_model]
    when "PDB"
      redirect_to :controller => "structures", :action => "search", :query => params[:query]
    when "SCOP"
      redirect_to :controller => "scops", :action => "search", :query => params[:query]
    else
      redirect_to "/"
    end
  end
end
