class VectorSpace
  STOP_WORDS = %w[
    a b c d e f g h i j k l m n o p q r s t u v w x y z
    an and are as at be by for from has he in is it its
    of on that the to was were will with upon without among
  ]
  
  doc1 = "I'm not even going to mention any TV series."
  doc2 = "The Wire is the best thing ever. Fact."
  doc3 = "Some would argue that Lost got a bit too wierd after season 2."
  doc4 = "Lost is surely not in the same league as The Wire."
  @@docs = [doc1, doc2, doc3, doc4]
  
  def tokenize(string)
    stripped = string.to_s.gsub(/[^a-z0-9\-\s\']/i, "") # remove punctuation
    tokens = stripped.split(/\s+/).reject(&:blank?).map(&:downcase).map(&:stem)
    tokens.reject { |t| STOP_WORDS.include?(t) }.uniq
  end
  
  def vector(doc)
    arr = Array.new(@vector_keyword_index.size, 0)
  
    tokens = tokenize(doc)
    tokens &= @vocab # ensure all tokens are in vocab
  
    tokens.each do |token|
      tf = tokens.count(token)
      num_docs_with_token = @@docs.count { |d| tokenize(d).include?(token) }
      idf = @@docs.size / num_docs_with_token
  
      index = @vector_keyword_index[token]
      arr[index] = tf * idf
    end
  
    return Vector.elements(arr) # create a vector from arr   
  end
  
  def cosine(vector1, vector2)
    dot_product = vector1.inner_product(vector2)
    dot_product / (vector1.r * vector2.r)
  end
  
  # ranks from 0 to 100
  def cosine_rank(vector1, vector2)
    (cosine(vector1, vector2) + 1) / 2 * 100
  end
  
  def run(query)
    @vocab = tokenize(@@docs.join(" "))
    
    @vector_keyword_index = begin
      index, offset = {}, 0      
    
      @vocab.each do |keyword|
        index[keyword] = offset
        offset += 1
      end
    
      index
    end
    
    @query = query
    query_vector = vector(@query)
    
    @@docs.each do |doc|
      doc_vector = vector(doc)
      rank = cosine_rank(query_vector, doc_vector)
      doc.instance_eval %{def rank; #{rank}; end} # bit mental
    end
    
    @results = @@docs.sort { |a,b| b.rank <=> a.rank } # highest to lowest
    
    
    @results.each { |doc| puts doc + " (#{doc.rank})" }
  end
      
  def input(doc)
    @@docs = doc
  end
  
end