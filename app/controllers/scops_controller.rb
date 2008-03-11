class ScopsController < ApplicationController

  def index
    @scops = Scop.root.registered_children

    respond_to do |format|
      format.html
    end
  end


  def search
    @keyword = params[:scop][:description]
    @hits = Scop.find_by_contents("#{@keyword} registered:(true)",
                                  :limit => :all)

    render :update do |page|
      page.replace_html "main_content",
                        :partial => "hit",
                        :collection => @hits
    end
  end


  def auto_complete_description
    query = params[:scop][:description]
    @scops = Scop.find_by_contents("#{query} registered:(true)",
                                   :limit => :all).sort_by(&:level)
    render :layout => false
  end


  def expand_subcategories
    @scop = Scop.find(params[:id])
    @scops = @scop.registered_children

    render :update do |page|
      page.insert_html  :bottom,
                        subcategories(dom_id(@scop)),
                        :partial => "category",
                        :collection => @scops
    end
  end


  def collapse_subcategories
    @scop = Scop.find(params[:id])

    render :update do |page|
      page.replace_html(subcategories(dom_id(@scop)))
      page.hide "collapse_subcategories_#{dom_id(@scop)}"
      page.show "expand_subcategories_#{dom_id(@scop)}"
    end
  end


  def show
    @scop = Scop.find(params[:id])
    @top_children = Scop.root.registered_children

    respond_to do |format|
      format.html
      format.js
    end
  end
end
