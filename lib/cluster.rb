 
#
# Cluster class, represents a centroid point along with its associated
# nearby points
#
 
class Clusterx
  INFINITY = 1.0/0
  attr_accessor :center, :points, :vector_keyword_index, :vocab, :centroid
  
  STOP_WORDS = %w[
    a b c d e f g h i j k l m n o p q r s t u v w x y z
    an and are as at be by for from has he in is it its
    of on that the to was were will with upon without among
  ]
  
  doc1 = "I'm not even going to mention any TV series."
  doc2 = "The Wire is the best thing ever. Fact."
  doc3 = "Some would argue that Lost got a bit too wierd after season 2."
  doc4 = "Lost is surely not in the same league as The Wire."
  @docs = [doc1, doc2, doc3, doc4]
  @data = []
  
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
      num_docs_with_token = @data.count { |d| tokenize(d).include?(token) }
      idf = @data.size / num_docs_with_token
  
      index = @vector_keyword_index[token]
      arr[index] = tf * idf
    end
  
    return Vector.elements(arr) # create a vector from arr   
  end
  
  def vector__(doc)
    arr = Array.new(@vector_keyword_index.size, 0)
  
    tokens = tokenize(doc)
    tokens &= @vocab # ensure all tokens are in vocab
  
    tokens.each do |token|
      tf = tokens.count(token)
      num_docs_with_token = @points.count { |d| tokenize(d).include?(token) }
      idf = @points.size / num_docs_with_token
  
      index = @vector_keyword_index[token]
      arr[index] = tf * idf
    end
  
    return Vector.elements(arr) # create a vector from arr   
  end
  
  def cosine(vector1, vector2)
    dot_product = vector1.inner_product(vector2)
    dot_product / (vector1.r * vector2.r)
  end
  
  def refresh_vocab
    @vocab = tokenize(@data.join(" "))
    
    @vector_keyword_index = begin
      index, offset = {}, 0      
    
      @vocab.each do |keyword|
        index[keyword] = offset
        offset += 1
      end
    
      index
    end
  end
  
  def refresh_vocab___
    @vocab = tokenize(@points.join(" "))
    
    @vector_keyword_index = begin
      index, offset = {}, 0      
    
      @vocab.each do |keyword|
        index[keyword] = offset
        offset += 1
      end
    
      index
    end
  end
 
  # Constructor with a starting centerpoint
  def initialize(center,data)
    @center = center
    @points = []
    @points << center
    
    @data = data
    
    self.refresh_vocab
    self.get_centroid
  end
  
  def initialize___(center)
    @center = center
    @points = []
    @points << center
    self.refresh_vocab
    self.get_centroid
  end
 
  # Recenters the centroid point and removes all of the associated points
  def _recenter!
    xa = ya = 0
    old_center = @center
     
    # Sum up all x/y coords
    @points.each do |point|
      xa += point.x
      ya += point.y
    end
 
    # Average out data
    xa /= points.length
    ya /= points.length
 
    # Reset center and return distance moved
    @center = Point.new(xa, ya)
    return (1-old_center.dist_to(center))
  
  end
  
  def recenter!   
    
    old_center = @center
    
    max_similar = 0
    @points.each do |point1|
      similar = 0
      #@points.each do |point2|
      #  if point1 != point2
      #    cos = cosine(vector(point1),vector(point2))
      #    similar += cos
      #    puts point1 + point2 + cos.to_s
      #  end        
      #end
      
      similar = cosine(vector(point1),vector(@points.join(" ")))
      
      if similar > max_similar
        @center = point1
        max_similar = similar
      end
      
      puts "ssss " + similar.to_s
    end
    
    return 1 # - cosine(vector(@center),vector(old_center))
  
  end

  def get_centroid
    
    if @points.count == 0
      return 0
    end
    
    tt = vector(@points.first)
    
    old_centroid = @centroid

    @points.each_with_index do |doc,index|
      if @points.first != doc
        tt += vector(doc)
        puts index
      end      
    end
    
    puts tt
    
    @centroid = tt/@points.count
    
    if !old_centroid.nil?
      return cosine(old_centroid,@centroid)
    else
      return 0
    end   
      
  end
  
  def clean_vocab(string)
    str = ""
    string.split(" ").each do |token|
      if @vocab.include?(token)
        str += token.to_s + " "
      end
    end
    return str.strip
  end
  
end