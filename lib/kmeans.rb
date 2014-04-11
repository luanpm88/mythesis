require 'csv'
require 'rubygems'
require 'gnuplot'

class Kmeans
  INFINITY = 1.0/0
  
  def kmeans(data, k, delta=0.99)
    clusters = []
     
    # Assign intial values for all clusters
    (1..k).each do |point|
      index = (data.length * rand).to_i
       
      rand_point = data[index]
      c = Cluster.new(rand_point)
       
      clusters.push c
      
    end
     
    # Loop
    while true
      # Assign points to clusters
      data.each do |point|
        max_similarity = 0
        max_cluster = nil
       
        # Find the closest cluster
        max_cluster = clusters.first
        clusters.each do |cluster|
          similarity = cluster.cosine(cluster.vector(cluster.clean_vocab(point)),cluster.centroid)
           
          if similarity < max_similarity
            max_similarity = similarity
            max_cluster = cluster
          end
        end
       
        # Add to closest cluster
        max_cluster.points.push point
        max_cluster.refresh_vocab        
      end
       
      # Check deltas
      max_delta = 0
       
      clusters.each do |cluster|
        dist_moved = cluster.get_centroid
         
        # Get largest delta
        if dist_moved > max_delta
          max_delta = dist_moved
        end
      end
      #puts "@@@@@@@@@@#########" +  max_delta.to_s + "--" + delta.to_s
      #sleep(1)
      # Check exit condition
      if max_delta > delta
        return clusters
      end
     
      # Reset points for the next iteration
      clusters.each do |cluster|
        cluster.points = []
      end
      
      
    end
  end
  
  def kmeans_fast(data, k, delta=0.001)
    clusters = []
    
    c = Cluster.new(data.first)
    
    clusters.push c
    
    data.each do |point|      
      if data.first != point
        clusters.first.points.push point
      end    
    end
    
    clusters.first.refresh_vocab    
    clusters.first.get_centroid
    
    return clusters    
  end
  
  def run
     data = []
     fn = 'public/test-kmean.csv'
     
     # Get all data
    CSV.foreach(fn) do |row|
      x = row[0].to_f
      y = row[1].to_f
       
      p = Point.new(x,y)
      data.push p
    end
     
    # Determine the number of clusters to find
    puts 'Number of clusters to find:'
    k = STDIN.gets.chomp!.to_i
     
    # Run algorithm on data
    clusters = kmeans(data, k)
     
    # Graph output by running gnuplot pipe
    ##Gnuplot.open do |gp|
      # Start a new plot
    ##  Gnuplot::Plot.new(gp) do |plot|
    ##    plot.title fn
       
        # Plot each cluster's points
        clusters.each do |cluster|
          # Collect all x and y coords for this cluster
          # x = cluster.points.collect {|p| p.x }
          # y = cluster.points.collect {|p| p.y }
          
          puts cluster.center
           
          # Plot w/o a title (clutters things up)
    ##      plot.data << Gnuplot::DataSet.new([x,y]) do |ds|
    ##        ds.notitle
    ##      end
    ##    end
        end
    ##end
  end
end