class ScopsController < ApplicationController

  def index
    #    @scops = Scop.root.registered_children

    respond_to do |format|
      format.html
    end
  end

  # def search
  #   @search = Ultrasphinx::Search.new(:query => @keyword, :class_names => "Scop", :filters => { "registered" => 1 })
  #   @search.run
  #   @hits = @search.results
  #   
  #   render :update do |page|
  #     page.replace_html "main_content",
  #                       :partial => "hit",
  #                       :collection => @hits
  #   end
  # end


#  def auto_complete_description
#    @sphinx = Ultrasphinx::Search.new(:query => params[:scop][:description],
#                                      :class_names => "Scop",
#                                      :filters => { "registered" => 1 })
#    @sphinx.run
#    @scops = @sphinx.results
#
#    render :layout => false
#  end


#  def expand_subcategories
#    @scop = Scop.find(params[:id])
#    @scops = @scop.registered_children
#
#    render :update do |page|
#      page.insert_html  :bottom,
#                        subcategories(dom_id(@scop)),
#                        :partial => "category",
#                        :collection => @scops
#    end
#  end
#
#
#  def collapse_subcategories
#    @scop = Scop.find(params[:id])
#
#    render :update do |page|
#      page.replace_html(subcategories(dom_id(@scop)))
#      page.hide "collapse_subcategories_#{dom_id(@scop)}"
#      page.show "expand_subcategories_#{dom_id(@scop)}"
#    end
#  end


#  def show
#    @scop = Scop.find(params[:id])
#    @top_children = Scop.root.registered_children
#
#    respond_to do |format|
#      format.html
#      format.js
#    end
#  end
end
