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
      c = Cluster.new(rand_point,data)
      
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
        max_index = 0
        clusters.each_with_index do |cluster,index|
          
          #puts cluster.centroid
          #puts cluster.points.count
          
          similarity = cluster.cosine(cluster.vector(point),cluster.centroid)

          if similarity > max_similarity
            max_similarity = similarity
            max_cluster = cluster
            max_index = index
          end
          
          puts similarity.to_s
          
        end
        puts "###" +  max_similarity.to_s
        puts "###" +  max_index.to_s
        #sleep(2)
       
        # Add to closest cluster
        max_cluster.points.push point
        #max_cluster.refresh_vocab        
      end
       
      # Check deltas
      min_delta = 1
       
      clusters.each do |cluster|
        #cluster.refresh_vocab
        dist_moved = cluster.get_centroid
         
         puts "^^^^^^^ " + dist_moved.to_s
        # Get largest delta
        if dist_moved < min_delta
          min_delta = dist_moved
        end
      end
      #puts "@@@@@@@@@@#########" +  max_delta.to_s + "--" + delta.to_s
      #sleep(1)
      # Check exit condition
      puts "min: " + min_delta.to_s
      if min_delta > delta
        break clusters
      end
     
      # Reset points for the next iteration
      clusters.each do |cluster|
        cluster.points = []
      end
      
      
    end
    
    maxcluster = clusters.first
    maxcount = 0
    clusters.each do |cluster|
        count = cluster.points.count #cluster.refresh_vocab
        
        if count > maxcount
          maxcount = count
          maxcluster = cluster
        end
    end
    puts maxcluster.centroid
    return {'clusters' => clusters, 'maxcluster' => maxcluster}
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