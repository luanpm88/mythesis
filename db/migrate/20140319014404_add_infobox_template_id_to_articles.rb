class AddInfoboxTemplateIdToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :infobox_template_id, :integer
  end
end
