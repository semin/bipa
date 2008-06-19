class TaxaController < ApplicationController

  def children
    if params[:root] == "root"
      children = TaxonomicNode.find(1).children
    else
      children = TaxonomicNode.find(params[:root]).children
    end

    children.each do |child|
      child[:tree_title] = child.tree_title
      if child.children.size > 0
        child[:hasChildren] = true
      end
    end

    respond_to do |format|
      format.json { render :json => children.to_json }
    end
  end

  def tabs
    @node = TaxonomicNode.find(params[:id])

    respond_to do |format|
      format.html { render :text => "#{@node.id}, #{@node.scientific_name.name_txt}" }
    end
  end

  def search
    @query = params[:query]
    @hits = TaxonomicName.search(@query)

    respond_to do |format|
      format.html
    end
  end
end
