class TaxonomicNode < ActiveRecord::Base

  acts_as_tree

  has_many  :taxonomic_names

  has_one   :scientific_name,
            :class_name   => "TaxonomicName",
            :foreign_key  => "taxonomic_node_id",
            :conditions   => ["name_class = 'scientific name'"]

  def tree_title
    %Q^<a href="#" onclick="new Ajax.Updater('main_content', '/taxonomy/tabs/#{id}', {asynchronous:true, evalScripts:true, onLoading:function(request){ Element.hide('main_content'); Element.show('main_spinner') }, onComplete:function(request){ Element.hide('main_spinner'); Element.show('main_content'); }}); return false;">[TaxID:#{id}]: #{scientific_name.name_txt}</a>^
  end
end
