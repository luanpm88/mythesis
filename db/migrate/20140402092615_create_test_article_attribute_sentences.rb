class CreateTestArticleAttributeSentences < ActiveRecord::Migration
  def change
    create_table :test_article_attribute_sentences do |t|
      t.integer :article_id
      t.integer :attribute_id
      t.text :sentence

      t.timestamps
    end
  end
end
