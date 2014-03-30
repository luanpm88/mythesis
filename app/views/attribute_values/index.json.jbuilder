json.array!(@attribute_values) do |attribute_value|
  json.extract! attribute_value, :id, :article_id, :attribute_id, :value
  json.url attribute_value_url(attribute_value, format: :json)
end
