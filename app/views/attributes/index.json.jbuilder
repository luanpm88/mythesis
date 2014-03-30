json.array!(@attributes) do |attribute|
  json.extract! attribute, :id, :name, :infobox_template_id
  json.url attribute_url(attribute, format: :json)
end
