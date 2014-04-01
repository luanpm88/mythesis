class Article < ActiveRecord::Base
  validates :title, presence: true, uniqueness: true
  
  belongs_to :infobox_template
  
  
  ##1
  def self.import
    #infobox template
    infobox_template = InfoboxTemplate.where(name: "university").first
    
    # new method
    reader = Nokogiri::XML::Reader(File.open("public/data.xml"))
    @count = 0
    @logstr = '';
    reader.each do |node|
            if node.name == 'page' and node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
                    @count = @count + 1                    
                    if @count > 0
                            page = Nokogiri::XML(node.outer_xml)
                            # Article.create(:name => page.css("title").text, :content => page.css("content").text)
                            
                            content = page.css("text").text
                            
                            val = /\{\{infobox\s*#{infobox_template.name}(.+)((.*)(\{\{(.+)\}\})(.*))*\}\}/m.match(content.downcase)
                            if !val.nil?
                              Article.create(:title => page.css("title").text,
                                             :content => page.css("text").text,
                                             :content_html => Wikitext::Parser.new.parse(page.css("text").text),
                                             :infobox_template_id => infobox_template.id
                                             )
                              
                              article = Article.where(:title => page.css("title").text).first
                                    
                              # puts @count.to_s + " " + page.css("title").text
                              # arr = val[1].split('|')
                              # arr.each {|item| puts ai  item.split('=')[0]}
                              
                              pparts = val[1].split("}}")
                              str = ""
                              pparts.each do |p|
                                if !/\{\{/m.match(p).nil?
                                  str += p+"}}"
                                else
                                  str += p
                                  break
                                end
                              end
                              
                              
                              inner = str
                              lines = inner.split(/\n\s*\|/m)
                              lines.each do |line|
                                if /\=/.match(line)
                                  parts = line.split("=")
                                  attr_name = parts[0].gsub(/\s*\|\s*/,"").strip
                                  attr_value = line.gsub(parts[0]+'=','').strip
                                  # puts attr_name # + ": " + line.gsub(parts[0]+'=','').strip + "\n"
                                  # puts line.gsub(parts[0]+'=','').strip
                                                                    
                                  attribute = infobox_template.attributes.where(name: attr_name).first
                                  if attribute.nil?                                    
                                    attribute = infobox_template.attributes.create(name: attr_name)
                                  end
                                  
                                  puts attribute.name
                                  @logstr += attribute.name + "\n"                                  
                                  
                                  attribute_value = AttributeValue.where(article_id: article.id, attribute_id: attribute.id).first
                                  if attribute_value.nil?                                    
                                    AttributeValue.create(article_id: article.id, attribute_id: attribute.id, value: attr_value)                                  
                                  end
                                  
                                  
                                  ### infobox_template.attributes.create(name: attr_name)
                                end
                                # sleep(0.1)
                              end
                              
                              puts "#######################"
                              @logstr += "#################\n"
                                                            
                            end
                            
                            # sleep(0.1)
                    end
            end
    end
    File.open("public/log.txt", "w") { |file| file.write @logstr }
  end
  
  
  ##2
  def self.create_raw_attribute_value
    @avs = AttributeValue.all
    
    @avs.each do |av|
      puts av.article.title + ": " + av.value.gsub(/\<ref(.+)\<\/ref\>/m,'').gsub(/\{\{(.+)\}\}/m, '').gsub(/\[\[(.+)\|/m, '').gsub(/[\[|\]]/m, '').gsub(/\<(.+)\/\>/m, '').gsub(/\<br\>/m, '').gsub(/\'\'/m,'')
      av.raw_value = av.value.gsub(/\<ref(.+)\<\/ref\>/m,'').gsub(/\{\{(.+)\}\}/m, '').gsub(/\[\[(.+)\|/m, '').gsub(/[\[|\]]/m, '').gsub(/\<(.+)\/\>/m, '').gsub(/\<br\>/m, '').gsub(/\'\'/m,'')
      av.save
      #sleep(0.01)
    end
  end
  
  def self.create_senteces_file
    article = Article.first
    
    File.open("public/senteces.txt", "w") { |file| file.write article.content_html.gsub(/<([^>\/\s]+)([^>]*)>/,'<\1>') }
  end
  
  
  ##3
  def self.write_article_to_files
    #system("public/opennlp-tools/bin/opennlp SentenceDetector en-sent.bin < ~/rails-apps/mythesis2/public/senteces.txt > ~/rails-apps/mythesis2/public/senteces_output.txt")
    #bin/opennlp SentenceDetector en-sent.bin < ~/rails-apps/mythesis2/public/senteces.txt > ~/rails-apps/mythesis2/public/senteces_output.txt
    
    
    infobox_template = InfoboxTemplate.where(name: "university").first
    
    infobox_template.articles.each do |article|
      #content_fixed = article.content_html.gsub('{{'+/(?=\{\{((?:[^(\{\{)(\}\})]++|\{\{\g<1>\}\})++)\}\})/m.match(article.content_html)[1]+'}}', '')
      
      content_fixed = article.content_html.gsub(/<([^>\/\s]+)([^>]*)>/m,'<\1>').gsub(/\&lt\;ref\&gt\;\&lt\;\/ref\&gt\;/m,'')
      
      while content_fixed.gsub!(/\{\{[^\{\}]*?\}\}/m, ''); end
      
      File.open("public/articles/#{infobox_template.name}/#{article.title.gsub(/[\s\&]/,'_')}.txt", "w") { |file| file.write content_fixed }

    end
    
    infobox_template.articles.each do |article|
      system("public/opennlp-tools/bin/opennlp SentenceDetector en-sent.bin < ~/rails-apps/mythesis2/public/articles/#{infobox_template.name}/#{article.title.gsub(/[\s\&]/,'_')}.txt > ~/rails-apps/mythesis2/public/articles/#{infobox_template.name}/sentenced/#{article.title.gsub(/[\s\&]/,'_')}.txt")
    end
  end
  
  
  ##4
  def self.find_sentences_with_value
    infobox_template = InfoboxTemplate.where(name: "university").first
    infobox_template.attributes.all.each do |attribute|
      
      #if attribute.name != "name"
        attribute.attribute_values.each do |attribute_value|
          f = File.open("public/articles/university/sentenced/#{attribute_value.article.title.gsub(/[\s\&]/,'_')}.txt")
          
          match_count = 0
          while(current_line = f.gets)
            if attribute_value.value.downcase != '' && !current_line.downcase.index(attribute_value.value.downcase).nil?
              match_count = match_count + 1
              puts attribute.name + ": " + match_count.to_s + " => '" + attribute_value.value + "'" + " " + current_line;
              
              exsit = AttributeSentence.where("attribute_id=#{attribute.id} AND value='#{attribute_value.value}'").first
              
              if !exsit.nil?
                exsit.content = current_line
                exsit.save
              else
                as = AttributeSentence.new(value: attribute_value.value, content: current_line)
                as.attribute = attribute
                as.save
              end
              
              
              
              #sleep(0.3)
            end         
            
          end        
        end
      #end
      
    end
  end
  
  
  ##5
  def self.create_doccat_training_file
    infobox_template = InfoboxTemplate.where(name: "university").first
    
    str = ""
    
    infobox_template.attributes.each do |attribute|
      attribute.attribute_sentences.each do |as|
        str += as.attribute.name + " " + as.content if !as.attribute.name.nil? && !as.content.nil?
      end
    end
    File.open("public/doccat/#{infobox_template.name}/train/doccat_train.txt", "w") { |file| file.write  str}
  end
  
  
  ##6
  def self.train_doccat
    infobox_template = InfoboxTemplate.where(name: "university").first
    
    `bin/opennlp DoccatTrainer -model public/doccat/#{infobox_template.name}/model/doccat.bin -lang en -data public/doccat/#{infobox_template.name}/train/doccat_train.txt -encoding UTF-8`
  end
  
  ##7 gsub(/^([^\s]+\s){1}/,'')
  def self.create_train_for_filter_by_cluster
    infobox_template = InfoboxTemplate.where(name: "university").first
    
    
    
    infobox_template.attributes.each do |attribute|
      str = ""
      f = File.open("public/doccat/#{infobox_template.name}/train/doccat_train.txt")
      while(current_line = f.gets)
        if /^([^\s]+\s){1}/.match(current_line)[1] == attribute.name+" "
          str += current_line.gsub(/^([^\s]+\s){1}/,'')
        end
      end
      File.open("public/cluster/#{infobox_template.name}/train/#{attribute.name.gsub(/[\s\/]+/,'_')}.txt", "w") { |file| file.write  str}
    end
    
  end
  
  ##8
  def self.create_vector_space_for_attribute
    infobox_template = InfoboxTemplate.where(name: "university").first
    
    #attribute = infobox_template.attributes[13]
    attribute = infobox_template.attributes.find(554)
    #doc = []
    #f = File.open("public/doccat/#{infobox_template.name}/train/doccat_train.txt")
    #while(current_line = f.gets)
    #  if attribute.name == current_line.split(' ')[0]
    #    doc << current_line
    #  end     
    #end
    #
    ## create vector space
    #vs = VectorSpace.new
    #vs.input(doc)
    #vs.run("country")
    #
    #puts doc.count
    
    data = []
    fn = "public/cluster/#{infobox_template.name}/train/#{attribute.name.gsub(/[\s\/]+/,'_')}.txt"
    
    f = File.open(fn)
     # Get all data
    while(current_line = f.gets)
      data.push current_line
    end
     
    # Determine the number of clusters to find
    k = 2
    
    km = Kmeans.new
    # Run algorithm on data
    clusters = km.kmeans(data, k)
     
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
  
  ##9
  def self.create_training_data_for_CRF
    infobox_template = InfoboxTemplate.where(name: "university").first
    `mkdir public/crf/#{infobox_template.name}`
    `mkdir public/crf/#{infobox_template.name}/data`
    
    str = "";
    infobox_template.attributes.each do |attribute|
      #create config file for one attribute
      
      config_str = "basedir=public/crf/#{infobox_template.name}/"
      config_str += "\nnumlabels=5"
      config_str += "\ninname=#{attribute.name.gsub(/[\s\/]+/,'_')}"
      config_str += "\noutdir=#{attribute.name.gsub(/[\s\/]+/,'_')}"
      config_str += "\ndelimit=,	/ -():.;'?\#`&\"_"
      config_str += "\nimpdelimit=,"
      
      File.open("public/crf/#{infobox_template.name}/#{attribute.name.gsub(/[\s\/]+/,'_')}.conf", "w") { |file| file.write  config_str}
      
      training_tr = ""
      test_tr = ""
      attribute.attribute_sentences.each do |as|
        
        content = as.content.gsub(/\|/,'')
        as.value = as.value.gsub(/\|/,'')
        
        parts = content.downcase.split(as.value.downcase)
        parts[0].split(/\s+/).each do |term|
          training_tr += term + " |1\n" if term.strip != ""
        end
        
        as.value.downcase.split(/\s+/).each_with_index do |term,index|
          count = as.value.downcase.split(/\s+/).count
          if count == 1
            post = "2"
          else
            post = "3"
            if index == 0
              post = "2"
            end
            if index == count-1
              post = "4"
            end
          end          
          
          training_tr += term + " |#{post}\n"
        end
        
        parts[1].split(/\s+/).each do |term|
          training_tr += term + " |5\n" if term.strip != ""
        end


        training_tr += "\n"
        
        test_tr += content.downcase.strip.gsub(as.value.downcase, " "+as.value.downcase+" ").gsub(/\s+/, " ") + "\n"
      end
      
      `mkdir public/crf/#{infobox_template.name}/data/#{attribute.name.gsub(/[\s\/]+/,'_')}`
      File.open("public/crf/#{infobox_template.name}/data/#{attribute.name.gsub(/[\s\/]+/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.train.tagged", "w") { |file| file.write  training_tr}
      File.open("public/crf/#{infobox_template.name}/data/#{attribute.name.gsub(/[\s\/]+/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.test.tagged", "w") { |file| file.write  training_tr}
      File.open("public/crf/#{infobox_template.name}/data/#{attribute.name.gsub(/[\s\/]+/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.test.raw", "w") { |file| file.write  test_tr}
    end
  end
  
  def self.training_CRF
    infobox_template = InfoboxTemplate.where(name: "university").first
    
    infobox_template.attributes.each do |attribute|
      puts `java -cp lib/colt.jar:lib/CRF.jar:lib/CRF-Trove_3.0.2.jar:lib/LBFGS.jar:build:. iitb.Segment.Segment all -f public/crf/#{infobox_template.name}/#{attribute.name.gsub(/[\s\/]+/,'_')}.conf`
      sleep(5)
    end
  end
    
end
