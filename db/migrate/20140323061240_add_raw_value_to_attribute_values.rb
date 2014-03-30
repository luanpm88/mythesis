class AddRawValueToAttributeValues < ActiveRecord::Migration
  def change
    add_column :attribute_values, :raw_value, :text
  end
end
