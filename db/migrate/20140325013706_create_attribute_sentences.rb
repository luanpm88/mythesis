class CreateAttributeSentences < ActiveRecord::Migration
  def change
    create_table :attribute_sentences do |t|
      t.integer :attribute_id
      t.text :value
      t.text :content

      t.timestamps
    end
  end
end
