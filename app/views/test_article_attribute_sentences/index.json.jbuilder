json.array!(@test_article_attribute_sentences) do |test_article_attribute_sentence|
  json.extract! test_article_attribute_sentence, :id, :article_id, :attribute_id, :sentence
  json.url test_article_attribute_sentence_url(test_article_attribute_sentence, format: :json)
end
