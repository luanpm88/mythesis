class AddArticleIdToAttributeSentence < ActiveRecord::Migration
  def change
    add_column :attribute_sentences, :article_id, :integer
  end
end
