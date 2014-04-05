class AddTestValueToTestArticleAttributeSentence < ActiveRecord::Migration
  def change
    add_column :test_article_attribute_sentences, :test_value, :text
  end
end
