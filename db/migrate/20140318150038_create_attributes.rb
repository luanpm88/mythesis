class CreateAttributes < ActiveRecord::Migration
  def change
    create_table :attributes do |t|
      t.text :name
      t.integer :infobox_template_id

      t.timestamps
    end
  end
end
