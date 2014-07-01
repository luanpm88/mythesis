class Article < ActiveRecord::Base
  validates :title, presence: true, uniqueness: true
  
  belongs_to :infobox_template
  has_many :attribute_sentences
  has_many :attribute_values
  has_many :test_article_attribute_sentences
  
  @@template = 'actor'
  @@no_attributes = ['name','image','caption','imagesize','bgcolour','alt','latin_name','native_name','image_size'] # ['name','image','caption','imagesize','bgcolour','alt','latin_name','native_name','image_size']
  @@num = 10
  
  def self.write_log(log)
    str = ""
    if File.file?("public/log.txt")
      f = File.open("public/log.txt")
      while(line = f.gets)
        str += line
      end
    end
    str += log + " : " + Time.now.strftime("%d/%m/%Y %H:%M:%S") + "\n"
    
    File.open("public/log.txt", "w") { |file| file.write str }
  end
  
  ##1
  def self.import(maxxx)
    #infobox template
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    # new method
    reader = Nokogiri::XML::Reader(File.open("/media/luan/01CF3161B4B56810/MyThesis/enwiki-20110115-pages-articles.xml"))
    @count = 0
    @logstr = '';
    reader.each do |node|
            if node.name == 'page' and node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
                    
                    if @count < maxxx
                            page = Nokogiri::XML(node.outer_xml)
                            # Article.create(:name => page.css("title").text, :content => page.css("content").text)
                            
                            content = page.css("text").text
                            
                            val = /\{\{infobox\s*#{infobox_template.name.downcase}(.+)((.*)(\{\{(.+)\}\})(.*))*\}\}/m.match(content.downcase)
                            if !val.nil?
                              
                              
                              Article.create(:title => page.css("title").text,
                                             :content => page.css("text").text,
                                             :content_html => Wikitext::Parser.new.parse(page.css("text").text.gsub(/\[\[\s*[a-zA-Z0-9]+\:[^\[\]]+\]\]/mi, '')),
                                             :infobox_template_id => infobox_template.id
                                             )
                              @count = @count + 1
                              puts @count
                              
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
                                  attr_name = parts[0].gsub(/\s*\|\s*/,"").gsub(/[\[\]]/,"").strip
                                  attr_value = line.gsub(parts[0]+'=','').gsub(/<!--[\s\S]*?-->/,'').strip
                                                                    
                                  if !@@no_attributes.include?(attr_name) && attr_value != ''
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
                                  end
                                  
                                  ### infobox_template.attributes.create(name: attr_name)
                                end
                                # sleep(0.1)
                              end
                              
                              puts "#######################"
                              @logstr += "#################\n"
                                                            
                            end
                            
                            # sleep(0.1)
                    else
                      break
                    end
            end
    end
    
    count_articles = ((Article.count.to_f/10.00)*9.00).to_i
    
    Article.update_all("for_test=0","id <= "+count_articles.to_s)
    Article.update_all("for_test=1","id > "+count_articles.to_s)
    
  end
  
  ##1.0
  def self.calculate_train_test
    part = (Article.count.to_f/10.00).to_i
    
    num = 10 - @@num
    
    index = (part*num)
    
    Article.update_all("for_test=0","id <= " + index.to_s + " OR id > " + (index+part).to_s)
    Article.update_all("for_test=1","id > " + index.to_s + " AND id <= " + (index+part).to_s)
    
  end


  ##1.1
  def self.set_attribute_status
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    infobox_template.attributes.each do |attribute|
      count = AttributeValue.joins(:article).where(attribute_id: attribute.id).where("articles.for_test=0").count("article_id",distinct: true) #AttributeValue.where(attribute_id: attribute.id).count("article_id",distinct: true)
      total = infobox_template.articles.where(for_test: 0).count
      
      puts count.to_s + "/" + total.to_s
      
      if (count.to_f / total.to_f) < 0.15
        attribute.status = 0
      else
        attribute.status = 1
      end
      
      attribute.save
      
    end
  end


  ##2
  def self.create_raw_attribute_value
    @avs = AttributeValue.all
    log_str = ""
    @avs.each do |av|
      puts av.article.title + ": " + av.value.gsub(/\<ref(.+)\<\/ref\>/m,'').gsub(/\{\{(.+)\}\}/m, '').gsub(/\[\[(.+)\|/m, '').gsub(/[\[|\]]/m, '').gsub(/\<(.+)\/\>/m, '').gsub(/\<br\>/m, '').gsub(/\'\'/m,'')
      av.raw_value = av.value.gsub(/\<ref(.+)\<\/ref\>/m,'').gsub(/\{\{(.+)\}\}/m, '').gsub(/\[\[[^\]\[]+\|/m, '').gsub(/[\[|\]]/m, '').gsub(/\<(.+)\/\>/m, '').gsub(/\<br\>/m, '').gsub(/\'\'/m,'')
      log_str += av.value + " | " + av.raw_value + "\n"
      av.save
    end
    File.open("public/log_attribute_value.txt", "w") { |file| file.write log_str }
  end


  def self.create_senteces_file
    article = Article.first
    
    File.open("public/senteces.txt", "w") { |file| file.write article.content_html.gsub(/<([^>\/\s]+)([^>]*)>/,'<\1>') }
  end


  ##3
  def self.write_article_to_files
    #system("public/opennlp-tools/bin/opennlp SentenceDetector en-sent.bin < ~/rails-apps/mythesis2/public/senteces.txt > ~/rails-apps/mythesis2/public/senteces_output.txt")
    #bin/opennlp SentenceDetector en-sent.bin < ~/rails-apps/mythesis2/public/senteces.txt > ~/rails-apps/mythesis2/public/senteces_output.txt
    
    
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    `mkdir public/articles`
    `mkdir public/articles/#{infobox_template.name.gsub(/\s/,'_')}`
    `mkdir public/articles/#{infobox_template.name.gsub(/\s/,'_')}/sentenced`
    `mkdir public/articles/#{infobox_template.name.gsub(/\s/,'_')}/sentenced/train`
    `mkdir public/articles/#{infobox_template.name.gsub(/\s/,'_')}/sentenced/test`
    
    infobox_template.articles.each do |article|
      #check for test/train
      if article.for_test == 1
        for_d = "test"
      else
        for_d = "train"
      end
      
      
      content_fixed = article.content_html.gsub(/<([^>\/\s]+)([^>]*)>/m,'<\1>').gsub(/\<p\>(\<a\>(.{2,5})\:[^<]+\<\/a\>\s?)+\<\/p\>/mi, '')#.gsub(/\&lt\;ref\&gt\;[^(\&lt\;ref\&gt\;)(\&lt\;\/ref\&gt\;)]*\&lt\;\/ref\&gt\;/m,"")      
      while content_fixed.gsub!(/\{\{[^\{\}]*?\}\}/m, ''); end      
      while content_fixed.gsub!(/\{[^\{\}]*?\}/m, ''); end      
      content_fixed = content_fixed.gsub(/\&lt\;ref(.*?)\&gt\;(.*?)\&lt\;\/ref\&gt\;/im,"")
      
      begin
        File.open("public/articles/#{infobox_template.name.gsub(/\s/,'_')}/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt", "w") { |file| file.write content_fixed }
      rescue
        puts "some error"
      end
      
      system("java -jar bin/SD.jar public/articles/#{infobox_template.name.gsub(/\s/,'_')}/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt public/articles/#{infobox_template.name.gsub(/\s/,'_')}/sentenced/#{for_d}/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt")
      
      puts "sentDetect: " + article.title
      
    end

  end
  
  ##3.1
  def self.clean_sentence_files
    
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    infobox_template.articles.each do |article|
      #check for test/train
      if article.for_test == 1
        for_d = "test"
      else
        for_d = "train"
      end
      
      
      #system("bin/opennlp SentenceDetector en-sent.bin < public/articles/#{infobox_template.name.gsub(/\s/,'_')}/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt > public/articles/#{infobox_template.name.gsub(/\s/,'_')}/sentenced/#{for_d}/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt")
      f = File.open("public/articles/#{infobox_template.name.gsub(/\s/,'_')}/sentenced/#{for_d}/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt")
      str = ""
      str_pp = ""
      while(current_line = f.gets)
        current_line = current_line.gsub(/\<li\>(.+)/i,'').gsub(/(.+)\<\/li\>/i,'').gsub(/\<h3\>(.+)/i,'').gsub(/\<h2\>(.+)/i,'').gsub('&lt;','').gsub('&gt;','').gsub(/\-(\-)+/,'').gsub(/\=(\=)+/,'').gsub(/\s+/,' ').strip
        if current_line != '' && current_line.gsub(/\<[^\>\<]+>/,'').gsub(/\s+/,' ').strip.length > 10
          str += current_line.strip + "\n"
          #str_pp += current_line.gsub('>','> ').gsub('<',' <').gsub(/([\)\(])/,' \1 ').gsub(/\s+/,' ').strip + "\n"
          str_pp += current_line.strip + "\n"
        end
      end
      
      File.open("public/articles/#{infobox_template.name.gsub(/\s/,'_')}/sentenced/#{for_d}/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}_clean.txt", "w") { |file| file.write  str}
      File.open("public/articles/#{infobox_template.name.gsub(/\s/,'_')}/sentenced/#{for_d}/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}_clean_pp.txt", "w") { |file| file.write  str_pp}
      
    end
  end
  
  
  ##4
  def self.find_sentences_with_value
    AttributeSentence.delete_all
    
    infobox_template = InfoboxTemplate.where(name: @@template).first
    infobox_template.attributes.where(status: 1).all.each do |attribute|
      
      #if attribute.name != "name"
        attribute.attribute_values.each do |attribute_value|
          
          begin
            if attribute_value.article.for_test == 0
              f = File.open("public/articles/#{infobox_template.name.gsub(/\s/,'_')}/sentenced/train/#{attribute_value.article.title.gsub(/[\s\&\'\,\)\(\"]/,'_')}_clean.txt")
            else
              f = File.open("public/articles/#{infobox_template.name.gsub(/\s/,'_')}/sentenced/test/#{attribute_value.article.title.gsub(/[\s\&\'\,\)\(\"]/,'_')}_clean.txt")
            end
            
            match_count = 0
            while(current_line = f.gets)
                            
              if attribute_value.value.downcase != '' && !current_line.downcase.index(attribute_value.value.downcase).nil?
                match_count = match_count + 1
                puts attribute.name + ": " + match_count.to_s + " => '" + attribute_value.value + "'" + " " + current_line;
                
                exsit = AttributeSentence.where("article_id = #{attribute_value.article_id} AND attribute_id=#{attribute.id} AND value='#{attribute_value.value}'").first
                
                #if !exsit.nil?
                #  exsit.content = current_line
                #  exsit.save
                #else
                  as = AttributeSentence.new(article_id: attribute_value.article_id,value: attribute_value.value, content: current_line)
                  as.attribute = attribute
                  if attribute_value.article.for_test == 0
                    as.for_test = 0
                  else
                    as.for_test = 1
                  end
                  as.save
                #end
                #sleep(0.3)
              end         
              
            end
          rescue
            puts "sentence error"
          end
        end
      #end
      
    end
  end
  
  ##4.1 find attribute has found in sentences
  def self.find_notfound_attribute
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    infobox_template.attributes.where(status: 1).all.each do |attribute|
      counting =  AttributeSentence.where(attribute_id: attribute.id).count
      
      if counting == 0
        attribute.status = 0
        attribute.save
      else
        attribute.status = 1
        attribute.save
      end
      
    end
  end
  
  ##5
  def self.create_doccat_training_file
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    `mkdir public/doccat/#{infobox_template.name.gsub(/\s/,'_')}`
    `mkdir public/doccat/#{infobox_template.name.gsub(/\s/,'_')}/train`
    
    str = ""
    
    infobox_template.attributes.where(status: 1).each do |attribute|
      if !@@no_attributes.include?(attribute.name)
        attribute.attribute_sentences.where(for_test: 0).each do |as|
          #str += as.attribute.name + " " + as.content.gsub('>','> ').gsub('<',' <').gsub(/([\)\(])/,' \1 ').gsub(/\s+/,' ').strip + "\n" if !as.attribute.name.nil? && !as.content.nil?
          str += as.attribute.name + " " + as.content.strip + "\n" if !as.attribute.name.nil? && !as.content.nil?
        end
      end
    end
    File.open("public/doccat/#{infobox_template.name.gsub(/\s/,'_')}/train/doccat_train.txt", "w") { |file| file.write  str}
  end
  
  
  ##6
  def self.train_doccat
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    `mkdir public/doccat/#{infobox_template.name.gsub(/\s/,'_')}/model`
    
    `bin/opennlp DoccatTrainer -model public/doccat/#{infobox_template.name.gsub(/\s/,'_')}/model/doccat.bin -lang en -data public/doccat/#{infobox_template.name.gsub(/\s/,'_')}/train/doccat_train.txt -encoding UTF-8`
  end
  
  ##6.1 //// test
  def self.doccat_test_files
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    #article = infobox_template.articles.first
    
    `mkdir public/doccat/#{infobox_template.name.gsub(/\s/,'_')}/test`
    puts infobox_template.articles.where(for_test: 1).count
    infobox_template.articles.where(for_test: 1).each do |article|
          
      
      #if !File.directory?("public/doccat/#{infobox_template.name.gsub(/\s/,'_')}/test/#{article.title.gsub(/[\s\&]/,'_')}")
      
        `mkdir public/doccat/#{infobox_template.name.gsub(/\s/,'_')}/test/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}`
        
        `java -jar bin/DoccatRun.jar public/doccat/#{infobox_template.name.gsub(/\s/,'_')}/model/doccat.bin public/articles/#{infobox_template.name.gsub(/\s/,'_')}/sentenced/test/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}_clean_pp.txt public/doccat/#{infobox_template.name.gsub(/\s/,'_')}/test/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}/all.txt`
        
        begin
        
          f = File.open("public/doccat/#{infobox_template.name.gsub(/\s/,'_')}/test/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}/all.txt")
          
          
          collection = {}
          while(current_line = f.gets)
            parts = current_line.split("$$$@@@%%%")
            attr = parts[0]
            value = parts[1]
            if parts.count > 1
              if !collection[attr].nil?
                collection[attr] << value
              else
                collection[attr] = []
                collection[attr] << value
              end
            end          
          end
          
          collection.map { |name,sentences|
            str = ""
            
            sentences.each {|s| str += s.strip + "\n"}
            
            begin
              File.open("public/doccat/#{infobox_template.name.gsub(/\s/,'_')}/test/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}/#{name.gsub(/[\s\/]+/,'_')}.txt", "w") { |file| file.write  str}
            rescue
              puts "some error"
            end
          }
        
        rescue
          puts "read article error"        
        end     
    end
    
  end
  
  ##6.1.new //// test
  def self.doccat_test_files_new
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    #article = infobox_template.articles.first
    
    `mkdir public/doccat/#{infobox_template.name.gsub(/\s/,'_')}/test`
    puts infobox_template.articles.where(for_test: 1).count
    infobox_template.articles.where(for_test: 1).each do |article|
          
      
      #if !File.directory?("public/doccat/#{infobox_template.name.gsub(/\s/,'_')}/test/#{article.title.gsub(/[\s\&]/,'_')}")
      
        `mkdir public/doccat/#{infobox_template.name.gsub(/\s/,'_')}/test/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}`
        
        puts `java -jar bin/DoccatRun2.jar public/doccat/#{infobox_template.name.gsub(/\s/,'_')}/model/doccat.bin public/articles/#{infobox_template.name.gsub(/\s/,'_')}/sentenced/test/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}_clean_pp.txt public/doccat/#{infobox_template.name.gsub(/\s/,'_')}/test/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}/all.txt`
        
        begin
        
          f = File.open("public/doccat/#{infobox_template.name.gsub(/\s/,'_')}/test/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}/all.txt")
          
          
          collection = {}
          while(current_line = f.gets)
            parts = current_line.split("$$$@@@%%%")
            attrs = parts[0]
            value = parts[1]
            
            
            
            if parts.count > 1
              
              attr_parts = attrs.split(/\s+/)
              
              #get min rate
              rates = []
              attr_parts.each do |item|
                matches = /(.+)\[(.+)\]/.match(item)
                
                rates << matches[2].to_f
                
              end
              rates = rates.sort { |x,y| y <=> x }
              puts rates
              
              attr_parts.each do |item|
                matches = /(.+)\[(.+)\]/.match(item)
                
                if matches[2].to_f > 0.0000
                  if !collection[matches[1]].nil?
                    #collection[matches[1]] << matches[2].to_s + "\t" + value
                    collection[matches[1]] << value
                  else
                    collection[matches[1]] = []
                    #collection[matches[1]] << matches[2].to_s + "\t" + value
                    collection[matches[1]] << value
                    
                  end
                end    
                  
                
              end
              puts "\n"
              
            end          
          end
          
          collection.map { |name,sentences|
            str = ""
            
            sentences.each {|s| str += s.strip + "\n"}
            
            begin
              File.open("public/doccat/#{infobox_template.name.gsub(/\s/,'_')}/test/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}/#{name.gsub(/[\s\/]+/,'_')}.txt", "w") { |file| file.write  str}
            rescue
              puts "some error"
            end
          }
        
        rescue
          puts "read article error"        
        end     
    end
    
  end
  
  ###test function
  def self.test_cluster
    cluster = ''
                File.open("public/cluster/actor/model/birth_name.bin") do |file|
                  cluster = Marshal.load(file)
                end
    
                f = File.open("public/doccat/actor/test/Gedeon_Burkhard/birth_name.txt")
                current_line = f.gets.strip
                
                similar = cluster.centroid.cosine_similarity(Clusterer::Document.new(current_line))
                
                puts "0: " + current_line
                puts "$$$$: " + similar.to_s
                
                
                c_sentence = current_line
                puts current_line
                max_similar = similar                
                count = 0
                while(current_line = f.gets)
                  count += 1                  
                  puts count.to_s + ": " + current_line
                  
                  # similar = cluster.cosine(cluster.vector(cluster.clean_vocab(current_line)), cluster.centroid)
                  
                  similar = cluster.centroid.cosine_similarity(Clusterer::Document.new(current_line))
                  
                  if similar > max_similar
                    max_similar = similar
                    c_sentence = current_line
                  end
                  
                  puts "$$$$: " + similar.to_s
                  #sleep(1)
                end
                
                puts "MAX$$$$: " + max_similar.to_s
                #sleep(10)
  end
  
  
  ##6.2 ///test
  def self.filter
    TestArticleAttributeSentence.delete_all
    
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    article = infobox_template.articles.first
    
    infobox_template.attributes.where(status: 1).each do |attribute|
      
      if !@@no_attributes.include?(attribute.name)
        if File.file?("public/cluster/#{infobox_template.name.gsub(/\s/,'_')}/model/#{attribute.name.gsub(/[\s\/]+/,'_')}.bin")
        
          cluster = ""
          
          
         
          infobox_template.articles.where(for_test: 1).each do |article|
            
            puts "++++++++++++++++++++++++++++++++++++++++"
            puts attribute.name + "::::"
            
            exsit = TestArticleAttributeSentence.where(article_id: article.id, attribute_id: attribute.id).first
            if exsit.nil?
              #puts "not exsit!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
              test_lines = []
              if File.file?("public/doccat/#{infobox_template.name.gsub(/\s/,'_')}/test/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.txt")
                
                File.open("public/cluster/#{infobox_template.name.gsub(/\s/,'_')}/model/#{attribute.name.gsub(/[\s\/]+/,'_')}.bin") do |file|
                  cluster = Marshal.load(file)
                end
                
                # f = File.open("public/doccat/#{infobox_template.name.gsub(/\s/,'_')}/test/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.txt")
                f = File.open("public/articles/#{infobox_template.name.gsub(/\s/,'_')}/sentenced/test/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}_clean.txt")
                
                current_line = f.gets.strip
                
                similar = cluster.centroid.cosine_similarity(Clusterer::Document.new(current_line))
                
                #test_str += similar.to_s + "\t" + (similar.to_f + current_line.split("\t")[0].to_f).to_s + "\t" + current_line.strip + "\n"
                #hash = {"doccat" => current_line.split("\t")[0].to_f, "cluster" => similar.to_f, "content" => current_line.split("\t")[1], "total" => similar.to_f + current_line.split("\t")[0].to_f}
                #test_lines << hash
                
                puts "0: " + current_line
                puts "$$$$: " + similar.to_s
                
                c_sentence = current_line
                puts current_line
                max_similar = similar
                
                count = 0
                while(current_line = f.gets)
                  count += 1                  
                  puts count.to_s + ": " + current_line
                  
                  similar = cluster.centroid.cosine_similarity(Clusterer::Document.new(current_line.strip))
                  
                  #test_str += similar.to_s + "\t" + (similar.to_f + current_line.strip.split("\t")[0].to_f).to_s + "\t" + current_line.strip + "\n"
                  #hash = {"doccat" => current_line.split("\t")[0].to_f, "cluster" => similar.to_f, "content" => current_line.split("\t")[1], "total" => similar.to_f + current_line.split("\t")[0].to_f}
                  #test_lines << hash
                  
                  if similar > max_similar
                    max_similar = similar
                    c_sentence = current_line.strip
                  end
                  
                  puts "$$$$: " + similar.to_s
                end
                
                puts "MAX$$$$: " + max_similar.to_s

                exsit = TestArticleAttributeSentence.where(article_id: article.id, attribute_id: attribute.id).first
                
                if exsit.nil?
                  TestArticleAttributeSentence.create(article_id: article.id, attribute_id: attribute.id, sentence: c_sentence)
                else
                  exsit.sentence = c_sentence
                  exsit.save
                end
                
                File.open("public/doccat/#{infobox_template.name.gsub(/\s/,'_')}/test/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}_chosen.txt", "w") { |file| file.write c_sentence}
                
                
                #test_lines = test_lines.sort {|a,b| b["doccat"] <=> a["doccat"]}
                #
                #if test_lines.count
                #  test_str = ''
                #  count = 0
                #  test_lines.each do |h|
                #    count += 1
                #    test_str += count.to_s + "\t" + h["doccat"].round(2).to_s + "\t" + h["cluster"].round(2).to_s + "\t" + h["total"].round(2).to_s + "\t" + h["content"].strip.to_s + "\n"
                #  end
                #  File.open("public/doccat/#{infobox_template.name.gsub(/\s/,'_')}/test/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}_chosen_scorce.txt", "w") { |file| file.write test_str}
                #  
                #  test_lines = test_lines.sort {|a,b| b["cluster"] <=> a["cluster"]}
                #  test_str = ''
                #  count = 0
                #  test_lines.each do |h|
                #    count += 1
                #    test_str += count.to_s + "\t" + h["doccat"].round(2).to_s + "\t" + h["cluster"].round(2).to_s + "\t" + h["total"].round(2).to_s + "\t" + h["content"].strip.to_s + "\n"
                #  end
                #  File.open("public/doccat/#{infobox_template.name.gsub(/\s/,'_')}/test/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}_chosen_scorce2.txt", "w") { |file| file.write test_str}
                #  
                #  test_lines = test_lines.sort {|a,b| b["total"] <=> a["total"]}
                #  test_str = ''
                #  count = 0
                #  test_lines.each do |h|
                #    count += 1
                #    test_str += count.to_s + "\t" + h["doccat"].round(2).to_s + "\t" + h["cluster"].round(2).to_s + "\t" + h["total"].round(2).to_s + "\t" + h["content"].strip.to_s + "\n"
                #  end
                #  File.open("public/doccat/#{infobox_template.name.gsub(/\s/,'_')}/test/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}_chosen_scorce3.txt", "w") { |file| file.write test_str}
                #end
                
                
              end
              
            else
              #puts "exsit!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"              
            end
              
          end
          
        end
      end
      
      
        
    end
    
    
  end
  
  ##7 gsub(/^([^\s]+\s){1}/,'') //// train
  def self.create_train_for_filter_by_cluster
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    `mkdir public/cluster/#{infobox_template.name.gsub(/\s/,'_')}`
    `mkdir public/cluster/#{infobox_template.name.gsub(/\s/,'_')}/train`
    
    infobox_template.attributes.where(status: 1).each do |attribute|
      str = ""
      f = File.open("public/doccat/#{infobox_template.name.gsub(/\s/,'_')}/train/doccat_train.txt")
      while(current_line = f.gets)
        if !current_line.index('&lt;table') && !current_line.index('{') && !current_line.index('|')
          if /^([^\s]+\s){1}/.match(current_line)[1] == attribute.name+" "
            str += current_line.gsub(/^([^\s]+\s){1}/,'').strip+"\n"
          end
        end
      end
      File.open("public/cluster/#{infobox_template.name.gsub(/\s/,'_')}/train/#{attribute.name.gsub(/[\s\/]+/,'_')}.txt", "w") { |file| file.write  str}
    end
    
  end
  
  ##8 ///train
  def self.create_vector_space_for_attribute   
    
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    `mkdir public/cluster/#{infobox_template.name.gsub(/\s/,'_')}/model`
    
    infobox_template.attributes.where(status: 1).each do |attribute|
      puts attribute.attribute_sentences.count
      if !@@no_attributes.include?(attribute.name)
        data = []
        fn = "public/cluster/#{infobox_template.name.gsub(/\s/,'_')}/train/#{attribute.name.gsub(/[\s\/]+/,'_')}.txt"
        puts fn
        f = File.open(fn)
         # Get all data
        while(current_line = f.gets)
          data.push current_line.gsub('>','> ').gsub('<',' <').gsub(/([\)\(])/,' \1 ').gsub(/\s+/,' ').strip
          puts current_line.gsub('>','> ').gsub('<',' <').gsub(/([\)\(])/,' \1 ').gsub(/\s+/,' ')
        end
        puts "#####"+data.count.to_s
        
        if data.count > 0
          # Determine the number of clusters to find
          k = 1
          if data.count > 5
            k = (data.count/5).to_i
          end
          
          #km = Kmeans.new
          # Run algorithm on data
          # clusters = km.kmeans(data, k)
          
          #clusters = Clusterer::Clustering.cluster(:kmeans, data, no_of_clusters: k)
          clusters = Clusterer::Clustering.cluster(:kmeans, data)
          maxcluster = clusters.first
          maxcount = 0
          clusters.each do |cluster|
            count = cluster.documents.count #cluster.refresh_vocab
        
            if count > maxcount
              maxcount = count
              maxcluster = cluster
            end
          end

          model = {"clusters" => clusters, "maxcluster" => maxcluster}
          
          puts model["clusters"].count

          
          File.open("public/cluster/#{infobox_template.name.gsub(/\s/,'_')}/model/#{attribute.name.gsub(/[\s\/]+/,'_')}.bin",'w') do|file|
            Marshal.dump(model["maxcluster"], file)
          end

        end      
          
      end       
    end
  end
  
  ##9 //// train
  def self.create_training_data_for_CRF
    x_window = 3;
    
    infobox_template = InfoboxTemplate.where(name: @@template).first
    `mkdir public/crf/#{infobox_template.name.gsub(/\s/,'_')}`
    `mkdir public/crf/#{infobox_template.name.gsub(/\s/,'_')}/data`
    
    str = "";
    infobox_template.attributes.where(status: 1).each do |attribute|
      #create config file for one attribute
      
      config_str = "basedir=public/crf/#{infobox_template.name.gsub(/\s/,'_')}/"
      config_str += "\nnumlabels=5"
      config_str += "\ninname=#{attribute.name.gsub(/[\s\/]+/,'_')}"
      config_str += "\noutdir=#{attribute.name.gsub(/[\s\/]+/,'_')}"
      config_str += "\ndelimit=,	/ -():.;'?\#`&\"_"
      config_str += "\nimpdelimit=,"
      
      File.open("public/crf/#{infobox_template.name.gsub(/\s/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.conf", "w") { |file| file.write  config_str}
      
      training_tr = ""
      test_tr = ""
      attribute.attribute_sentences.where(for_test: 0).each do |as|
        
        
          content = as.content.gsub(/\|/,'').gsub('>','> ').gsub('<',' <').gsub(/\s+/,' ')
          as.value = as.value.gsub(/\|/,'')
          
          parts = content.downcase.split(as.value.downcase)
          parts[0].gsub(/([\,\.\:\!\?\)\(])/,' \1 ').gsub(/\s+/,' ').split(/\s+/).each_with_index do |term,index|
            count = parts[0].split(/\s+/).count
            
            training_tr += term + " |1\n" if term.strip != "" if index > (count - x_window - 1)
            test_tr += term + " " if term.strip != "" if index > (count - x_window - 1)
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
            test_tr += term + " "
          end
          
          puts 
          parts[1].gsub(/([\,\.\:\!\?\)\(])/,' \1 ').gsub(/\s+/,' ').split(/\s+/).each_with_index do |term,index|
            training_tr += term + " |5\n" if term.strip != "" if index < x_window + 1
            test_tr += term + " " if term.strip != "" if index < x_window + 1
          end
  
  
          training_tr += "\n"        
          test_tr += "\n"
        

        
      end
      
      `mkdir public/crf/#{infobox_template.name.gsub(/\s/,'_')}/data/#{attribute.name.gsub(/[\s\/]+/,'_')}`
      File.open("public/crf/#{infobox_template.name.gsub(/\s/,'_')}/data/#{attribute.name.gsub(/[\s\/]+/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.train.tagged", "w") { |file| file.write  training_tr}
      #File.open("public/crf/#{infobox_template.name.gsub(/\s/,'_')}/data/#{attribute.name.gsub(/[\s\/]+/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.test.tagged", "w") { |file| file.write  training_tr}
      #File.open("public/crf/#{infobox_template.name.gsub(/\s/,'_')}/data/#{attribute.name.gsub(/[\s\/]+/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.test.raw", "w") { |file| file.write  test_tr}
    end
  end
  
  ##10 ---- from 6.1 6.2 //// test
  def self.create_test_files_crf
    #code
    infobox_template = InfoboxTemplate.where(name: @@template).first

    
      infobox_template.attributes.where(status: 1).each do |attribute|
        str = ""
        ids_str = ""
        infobox_template.articles.where(for_test: 1).each do |article|
          test_s = TestArticleAttributeSentence.where(article_id: article.id, attribute_id: attribute.id).first
        
          if !test_s.nil? && test_s.sentence.strip != ''
            str += test_s.sentence.gsub('>','> ').gsub('<',' <').gsub(/([\)\(])/,' \1 ').gsub(/\s+/,' ') + "\n"
            ids_str += test_s.id.to_s + "\n"
          end
        
        end
      
        puts str
        #sleep(1)
        
        File.open("public/crf/#{infobox_template.name.gsub(/\s/,'_')}/data/#{attribute.name.gsub(/[\s\/]+/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.test.raw", "w") { |file| file.write  str } if str != ""
        File.open("public/crf/#{infobox_template.name.gsub(/\s/,'_')}/data/#{attribute.name.gsub(/[\s\/]+/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}_ids.test.raw", "w") { |file| file.write  ids_str } if ids_str != ""
      end
    
    
  end
  
  
  ##11 //// train
  def self.training_CRF
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    infobox_template.attributes.where(status: 1).each do |attribute|
      puts `java -cp lib/colt.jar:lib/CRF.jar:lib/CRF-Trove_3.0.2.jar:lib/LBFGS.jar:build:. iitb.Segment.Segment train -f public/crf/#{infobox_template.name.gsub(/\s/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.conf`
    end
  end
  
  ##12 //// test
  def self.test_CRF
    infobox_template = InfoboxTemplate.where(name: @@template).first
        
    infobox_template.attributes.where(status: 1).each do |attribute|
      begin
        File.open("public/crf/#{infobox_template.name.gsub(/\s/,'_')}/data/#{attribute.name.gsub(/[\s\/]+/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.test.raw")
        puts `java -cp lib/colt.jar:lib/CRF.jar:lib/CRF-Trove_3.0.2.jar:lib/LBFGS.jar:build:. iitb.Segment.Segment test -f public/crf/#{infobox_template.name.gsub(/\s/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.conf`
      rescue
        puts "some error!!!!!!!!!!!!!!"
      end
    end
    
  end
  
  ##13
  def self.get_result
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    infobox_template.attributes.where(status: 1).each do |attribute|
      file_name = "public/crf/#{infobox_template.name.gsub(/\s/,'_')}/out/#{attribute.name.gsub(/[\s\/]+/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.test.tagged"
      file_name_raw = "public/crf/#{infobox_template.name.gsub(/\s/,'_')}/data/#{attribute.name.gsub(/[\s\/]+/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}_ids.test.raw"
      puts file_name
      if File.file?(file_name)
        f = File.open(file_name)
        f_raw = File.open(file_name_raw)
        
        sentence = '';
        value = '';
        count2 = 0;
        count3 = 0;
        count4 = 0;
        while(current_line = f.gets)
         
          if current_line.strip != ''
            if current_line.index("|2")
              count2 += 1
              value += current_line.gsub(/\|[12345]/,'').strip + " " if count2 == 1              
            end
            
            if current_line.index('|3')
              count3 += 1
              value += current_line.gsub(/\|[12345]/,'').strip + " " if count2 == 1  
            end
            
            if current_line.index('|4')
              count4 += 1
              value += current_line.gsub(/\|[12345]/,'').strip + " " if count2 == 1 && count4 == 1
            end

          else
            current_line_draw = f_raw.gets
            taas = TestArticleAttributeSentence.find(current_line_draw.strip)
                        
            if !taas.nil?
              #if !value.nil? && value.strip != '' #(count2 == 1 && count3 > 0 && count4 == 1) || (count2 == 1 && count3 == 0 && count4 == 1) || (count2 == 1 && count3 == 0 && count4 == 0)
              if (count2 == 1 && count3 > 0 && count4 == 1) || (count2 == 1 && count3 == 0 && count4 == 1) || (count2 == 1 && count3 == 0 && count4 == 0)
                puts value + ": " + attribute.name
                taas.test_value = value.strip
              else
                taas.test_value = nil
              end
              
              taas.save
            end
            
            sentence = '';
            value = '';
            count2 = 0;
            count3 = 0;
            count4 = 0;
          end
        end
      end
    end
    
  end
  
  ##14.0
  def self.write_result_per_attribute
    infobox_template = InfoboxTemplate.where(name: @@template).first
      
    `mkdir public/result/#{infobox_template.name.gsub(/\s/,'_')}`
    `mkdir public/result/#{infobox_template.name.gsub(/\s/,'_')}/fold_#{@@num.to_s}`
    
    infobox_template.attributes.where(status: 1).each do |attribute|
      #count result
      str = ""
      correct = 0
      wrong = 0
      count_finded = 0
      
      infobox_template.articles.where(for_test: 1).each do |article|
        puts article.id

          
          
          article.test_article_attribute_sentences.where(attribute_id: attribute.id).each do |test|
            
            attribute_sentence = AttributeSentence.where(article_id: test.article_id, attribute_id: test.attribute_id).first
            puts attribute_sentence.nil?

            #puts test.test_value = "#########"
            
            if !attribute_sentence.nil? && !test.test_value.nil?                
                            
              attribute_value = AttributeValue.where(article_id: test.article_id, attribute_id: test.attribute_id).first
              
              if !attribute_value.raw_value.nil?
                
              
                    
                    puts attribute_value.raw_value
                    
                    if test.test_value.gsub(/\s+([\.\,])/,'\1').strip.downcase == attribute_value.raw_value.strip.downcase || test.test_value.gsub(/\s+([\.\,])/,'\1').gsub(/\.$/,'').strip.downcase == attribute_value.raw_value.strip.downcase || test.sentence.downcase.gsub(/\s+([\.\,])\s+/,'\1').index(attribute_value.raw_value.strip)
                      
                      str += count_finded.to_s + "\t" + "TRUE" + "\t" + attribute_value.article.title + "::" + attribute_value.attribute.name + "\t" + attribute_value.raw_value.to_s + " / #{test.test_value.gsub(/\s+([\.\,])/,'\1').strip.to_s}" + "\t\n" + test.sentence.strip + "\n\n"
                      #str += test.sentence.strip + "\n\n"
                      correct += 1;
                    else
                      str += count_finded.to_s + "\t" + "FALSE" + "\t" +  attribute_value.article.title + "::" + attribute_value.attribute.name + "\t" + attribute_value.raw_value.to_s + " / #{test.test_value.gsub(/\s+([\.\,])/,'\1').strip.to_s}" + "\t\n" + test.sentence.strip + "\n\n"
                      #str += test.sentence.strip + "\n\n"
                      wrong += 1;
                    end
                    
              
              end
              
            end
            if attribute_sentence.nil? && !test.test_value.nil?
              str += "#" + "\t" + "NEW" + "\t" +  test.attribute.name + "\t........ / #{test.test_value.to_s}" + "\t// " + test.sentence.strip + "\n\n"
            end
            if !test.test_value.nil?
              count_finded += 1
            end
          end
          
      end
      
      AttributeValue.joins(:article).where("articles.for_test=1").where(attribute_id: attribute.id).each do |value|
        
        attribute_sentence = AttributeSentence.where(article_id: value.article_id, attribute_id: value.attribute_id).first
        test_value = TestArticleAttributeSentence.where(article_id: value.article_id, attribute_id: value.attribute_id).first
        
        
        if !attribute_sentence.nil?
          
          if !test_value.nil? && test_value.test_value.nil? 
            str += "#" + "\t" + "null" + "\t" +  value.attribute.name + "\t" + value.raw_value.to_s + " / ..........\n\n"
          end
        
        
        end
      
        
      end
        
        
            
      total = AttributeSentence.where(for_test: 1).where(attribute_id: attribute.id).count("CONCAT(article_id,'---',attribute_id)",distinct: true)
      
      
      first_line = "Found: " + count_finded.to_s + "\n"
      first_line += "Found Not Null: " + (correct+wrong).to_s + "\n"
      first_line += "Correct: " + correct.to_s + "\n"
      first_line += "Wrong: " + wrong.to_s + "\n"
      first_line += "Total: " + total.to_s + "\n"
      first_line += "precision: " + (correct.to_f/((correct+wrong).to_f)).to_s + "\n" if correct+wrong > 0
      first_line += "recall: " + (correct.to_f/total.to_f).to_s + "\n" if total > 0
      first_line += "\n\n\n"
      
      
      File.open("public/result/#{infobox_template.name.gsub(/\s/,'_')}/fold_#{@@num.to_s}/#{attribute.name.gsub(/[\s\/]+/,'_')}.txt", "w") { |file| file.write  first_line + str}
      
      
    end
      
  end
  
  ##14
  def self.write_result
    infobox_template = InfoboxTemplate.where(name: @@template).first
      
      `mkdir public/result/#{infobox_template.name.gsub(/\s/,'_')}`
      `mkdir public/result/#{infobox_template.name.gsub(/\s/,'_')}/fold_#{@@num.to_s}`
      
      #count result
      str = ""
      correct = 0;
      wrong = 0;
      count_finded = 0;
      
      infobox_template.articles.where(for_test: 1).each do |article|
        puts article.id

          
          
          article.test_article_attribute_sentences.each do |test|
            
            attribute_sentence = AttributeSentence.where(article_id: test.article_id, attribute_id: test.attribute_id).first
            puts attribute_sentence.nil?

            #puts test.test_value = "#########"
            
            if !attribute_sentence.nil? && !test.test_value.nil?                
                            
              attribute_value = AttributeValue.where(article_id: test.article_id, attribute_id: test.attribute_id).first
              
              if !attribute_value.raw_value.nil?
                                    
                    puts attribute_value.raw_value
                    
                    if test.test_value.gsub(/\s+([\.\,])/,'\1').strip.downcase == attribute_value.raw_value.strip.downcase || test.test_value.gsub(/\s+([\.\,])/,'\1').gsub(/\.$/,'').strip.downcase == attribute_value.raw_value.strip.downcase || test.sentence.downcase.gsub(/\s+([\.\,])\s+/,'\1').index(attribute_value.raw_value.strip)
                    #if test.sentence.downcase.gsub(/\s+([\.\,])\s+/,'\1').index(attribute_value.raw_value.strip)
                      
                      str += count_finded.to_s + "\t" + "TRUE" + "\t" + attribute_value.article.title + "::" + attribute_value.attribute.name + "\t" + attribute_value.raw_value.to_s + " / #{test.test_value.gsub(/\s+([\.\,])/,'\1').strip.to_s}" + "\t\n" + test.sentence.strip + "\n\n"
                      #str += test.sentence.strip + "\n\n"
                      correct += 1;
                    else
                      str += count_finded.to_s + "\t" + "FALSE" + "\t" +  attribute_value.article.title + "::" + attribute_value.attribute.name + "\t" + attribute_value.raw_value.to_s + " / #{test.test_value.gsub(/\s+([\.\,])/,'\1').strip.to_s}" + "\t\n" + test.sentence.strip + "\n\n"
                      #str += test.sentence.strip + "\n\n"
                      wrong += 1;
                    end
                    
              
              end
              
            end
            if attribute_sentence.nil? && !test.test_value.nil?
              str += "#" + "\t" + "NEW" + "\t" +  test.attribute.name + "\t........ / #{test.test_value.to_s}" + "\t// " + test.sentence.strip + "\n\n"
            end
            if !test.test_value.nil?
              count_finded += 1
            end
          end
          
    end
      
    AttributeValue.joins(:article).where("articles.for_test=1").each do |value|
      
      attribute_sentence = AttributeSentence.where(article_id: value.article_id, attribute_id: value.attribute_id).first
      test_value = TestArticleAttributeSentence.where(article_id: value.article_id, attribute_id: value.attribute_id).first
      
      
      if !attribute_sentence.nil?
        
        if !test_value.nil? && test_value.test_value.nil? 
          str += "#" + "\t" + "null" + "\t" +  value.attribute.name + "\t" + value.raw_value.to_s + " / ..........\n\n"
        end
      
      
      end
    
      
    end
      
      
    artilce_count = infobox_template.articles.count.to_s
    artilce_test = infobox_template.articles.where(for_test: 0).count.to_s
    artilce_train = infobox_template.articles.where(for_test: 1).count.to_s
    
    attribute_count = infobox_template.attributes.count.to_s
    attribute_count_for_test = infobox_template.attributes.where(status: 1).count.to_s
    #attribute_count_high_rate = infobox_template.attributes.where(status: 1).where(high_rate: 1).count.to_s
    
    total = AttributeSentence.where(for_test: 1).count("CONCAT(article_id,'---',attribute_id)",distinct: true)
    
    first_line = "Total articles: " + artilce_count.to_s + "\n"
    first_line += "Articles for test: " + artilce_test.to_s + "\n"
    first_line += "Articles for train: " + artilce_train.to_s + "\n"
    first_line += "Total attributes: " + attribute_count.to_s + "\n"
    first_line += "Attributes with high occurrences: " + attribute_count_for_test.to_s + "/" + attribute_count.to_s + "\n" + "\n------------\n"
    #first_line += "Attributes with high precision: " + attribute_count_high_rate.to_s + "/" + attribute_count_for_test.to_s + "\n------------\n"
      
    
    first_line += "Found: " + count_finded.to_s + "\n"
    first_line += "Found Not Null: " + (correct+wrong).to_s + "\n"
    first_line += "Correct: " + correct.to_s + "\n"
    first_line += "Wrong: " + wrong.to_s + "\n"
    first_line += "Total: " + total.to_s + "\n"
    first_line += "precision: " + (correct.to_f/((correct+wrong).to_f)).to_s + "\n" if correct+wrong > 0
    first_line += "recall: " + (correct.to_f/total.to_f).to_s + "\n" if total > 0
    first_line += "\n\n\n"
    
    
    File.open("public/result/#{infobox_template.name.gsub(/\s/,'_')}/fold_#{@@num.to_s}/all.txt", "w") { |file| file.write  first_line + str}
  end
  
  def self.run_all
    #@@num = 10
    
    
    
    ####1
    #self.import(456)
    #self.write_log("#####1")
    ##
    ###1.0
    self.calculate_train_test
    self.write_log("#####1.0")
    #
    ###1.1
    self.set_attribute_status
    self.write_log("#####1.1")
    #
    ###2
    self.create_raw_attribute_value
    self.write_log("#####2")
    #
    ###3
    self.write_article_to_files
    self.write_log("#####3")
    #
    ###3.1
    self.clean_sentence_files
    self.write_log("#####3.1")
    #
    ###4
    self.find_sentences_with_value
    self.write_log("#####4")
    #
    ###4.1
    self.find_notfound_attribute
    self.write_log("#####4.1")
    #
    ###5
    self.create_doccat_training_file
    self.write_log("#####5")
    #
    ###6
    self.train_doccat
    self.write_log("#####6")
    #
    ###6.1.new
    self.doccat_test_files_new
    self.write_log("#####6.1.new")
    #
    ###7
    self.create_train_for_filter_by_cluster
    self.write_log("#####7")
    #
    ###8
    self.create_vector_space_for_attribute    
    self.write_log("#####8")
    #
    ##6.2
    self.filter
    self.write_log("#####6.2")
    #
    ###9
    self.create_training_data_for_CRF
    self.write_log("#####9")
    #
    ##11
    self.training_CRF
    self.write_log("#####11")   
        
    ##10
    self.create_test_files_crf
    self.write_log("#####10")
    
    ##12
    self.test_CRF
    self.write_log("#####12")
    
    ##13
    self.get_result
    self.write_log("#####13")
    
    ##14.0
    self.write_result_per_attribute
    self.write_log("#####14.0")
    
    ##14
    self.write_result
    self.write_log("#####14")
    
  end
  
  def self.run_all_folds
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    #ActiveRecord::Base.connection.execute("TRUNCATE TABLE articles RESTART IDENTITY")
    #ActiveRecord::Base.connection.execute("TRUNCATE TABLE attributes RESTART IDENTITY")
    #ActiveRecord::Base.connection.execute("TRUNCATE TABLE attribute_values RESTART IDENTITY")
    #ActiveRecord::Base.connection.execute("TRUNCATE TABLE attribute_sentences RESTART IDENTITY")
    #ActiveRecord::Base.connection.execute("TRUNCATE TABLE test_article_attribute_sentences RESTART IDENTITY")
    #  
    ####1
    #self.import(312)
    #self.write_log("#####1")
    ##

    #(1..10).each do |i|
      @@num = 1
      
      `rm -r public/crf/#{infobox_template.name.gsub(/\s/,'_')}`
      `rm -r public/doccat/#{infobox_template.name.gsub(/\s/,'_')}`
      `rm -r public/articles/#{infobox_template.name.gsub(/\s/,'_')}`
      `rm -r public/cluster/#{infobox_template.name.gsub(/\s/,'_')}`
      
      #ActiveRecord::Base.connection.execute("TRUNCATE TABLE articles RESTART IDENTITY")
      #ActiveRecord::Base.connection.execute("TRUNCATE TABLE attributes RESTART IDENTITY")
      #ActiveRecord::Base.connection.execute("TRUNCATE TABLE attribute_values RESTART IDENTITY")
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE attribute_sentences RESTART IDENTITY")
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE test_article_attribute_sentences RESTART IDENTITY")
    
      self.run_all
    #end
  end
  
  
    
end
