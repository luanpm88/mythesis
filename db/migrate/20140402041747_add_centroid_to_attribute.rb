class AddCentroidToAttribute < ActiveRecord::Migration
  def change
    add_column :attributes, :centroid, :text
  end
end
