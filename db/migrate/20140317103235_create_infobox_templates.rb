class CreateInfoboxTemplates < ActiveRecord::Migration
  def change
    create_table :infobox_templates do |t|
      t.text :name

      t.timestamps
    end
  end
end
