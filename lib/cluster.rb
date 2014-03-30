 
#
# Cluster class, represents a centroid point along with its associated
# nearby points
#
 
class Cluster
  INFINITY = 1.0/0
  attr_accessor :center, :points, :vector_keyword_index, :vocab
  
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
  def initialize(center)
    @center = center
    @points = []
    @points << center
    self.refresh_vocab
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
    return old_center.dist_to(center)
  
  end
  
  def recenter!   
    
    old_center = @center
    
    max_similar = 0
    @points.each do |point1|
      similar = 0
      @points.each do |point2|
        similar += cosine(vector(point1),vector(point2))
        puts point1 + point2 + cosine(vector(point1),vector(point2)).to_s
      end
      if similar > max_similar
        @center = point1
        max_similar = similar
        puts similar
      end      
    end
    
    return cosine(vector(@center),vector(old_center))
  
  end
  
end