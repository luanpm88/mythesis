class AddForTestToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :for_test, :integer
  end
end
