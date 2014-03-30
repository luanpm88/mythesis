json.array!(@infobox_templates) do |infobox_template|
  json.extract! infobox_template, :id, :name
  json.url infobox_template_url(infobox_template, format: :json)
end
