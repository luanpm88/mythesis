class AddForTestToAttributeSentences < ActiveRecord::Migration
  def change
    add_column :attribute_sentences, :for_test, :integer
  end
end
