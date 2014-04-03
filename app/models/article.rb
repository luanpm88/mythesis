class Article < ActiveRecord::Base
  validates :title, presence: true, uniqueness: true
  
  belongs_to :infobox_template
  has_many :attribute_sentences
  has_many :attribute_values
  
  
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
                                             :content_html => Wikitext::Parser.new.parse(page.css("text").text.gsub(/\[\[\s*category\:[^\[\]]+\]\]/mi, '')),
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
                                    AttributeValue.create(article_id: article.id, attribute_id: attribute.id, value: attr_value, raw_value: attr_value.gsub(/\<ref(.+)\<\/ref\>/m,'').gsub(/\{\{(.+)\}\}/m, '').gsub(/\[\[(.+)\|/m, '').gsub(/[\[|\]]/m, '').gsub(/\<(.+)\/\>/m, '').gsub(/\<br\>/m, '').gsub(/\'\'/m,''))                                  
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
  
  
  ##2###
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
    
    `mkdir public/articles/#{infobox_template.name}`
    `mkdir public/articles/#{infobox_template.name}/sentenced/train`
    `mkdir public/articles/#{infobox_template.name}/sentenced/test`
    
    infobox_template.articles.each do |article|
      #check for test/train
      if article.for_test == 1
        for_d = "test"
      else
        for_d = "train"
      end
      
      
      content_fixed = article.content_html.gsub(/<([^>\/\s]+)([^>]*)>/m,'<\1>').gsub(/\&lt\;ref\&gt\;\&lt\;\/ref\&gt\;/m,'').gsub(/\<p\>(\<a\>(.{2,5})\:[^<]+\<\/a\>\s?)+\<\/p\>/mi, '')
      
      while content_fixed.gsub!(/\{\{[^\{\}]*?\}\}/m, ''); end
      
      File.open("public/articles/#{infobox_template.name}/#{article.title.gsub(/[\s\&]/,'_')}.txt", "w") { |file| file.write content_fixed }
      system("bin/opennlp SentenceDetector en-sent.bin < public/articles/#{infobox_template.name}/#{article.title.gsub(/[\s\&]/,'_')}.txt > public/articles/#{infobox_template.name}/sentenced/#{for_d}/#{article.title.gsub(/[\s\&]/,'_')}.txt")
    end

  end
  
  
  ##4
  def self.find_sentences_with_value
    infobox_template = InfoboxTemplate.where(name: "university").first
    infobox_template.attributes.all.each do |attribute|
      
      #if attribute.name != "name"
        attribute.attribute_values.each do |attribute_value|
          
          if attribute_value.article.for_test == 0
            f = File.open("public/articles/university/sentenced/train/#{attribute_value.article.title.gsub(/[\s\&]/,'_')}.txt")
            
            match_count = 0
            while(current_line = f.gets)
              if attribute_value.value.downcase != '' && !current_line.downcase.index(attribute_value.value.downcase).nil?
                match_count = match_count + 1
                puts attribute.name + ": " + match_count.to_s + " => '" + attribute_value.value + "'" + " " + current_line;
                
                exsit = AttributeSentence.where("article_id = #{attribute_value.article_id} AND attribute_id=#{attribute.id} AND value='#{attribute_value.value}'").first
                
                if !exsit.nil?
                  exsit.content = current_line
                  exsit.save
                else
                  as = AttributeSentence.new(article_id: attribute_value.article_id,value: attribute_value.value, content: current_line)
                  as.attribute = attribute
                  as.save
                end
                #sleep(0.3)
              end         
              
            end
          end
        end
      #end
      
    end
  end
  
  
  ##5
  def self.create_doccat_training_file
    infobox_template = InfoboxTemplate.where(name: "university").first
    
    `mkdir public/doccat/#{infobox_template.name}`
    `mkdir public/doccat/#{infobox_template.name}/train`
    
    str = ""
    
    infobox_template.attributes.each do |attribute|
      if attribute.name != "name" && attribute.name != "latin_name" && attribute.name != "native_name"
        attribute.attribute_sentences.each do |as|
          if as.article.for_test == 0
            str += as.attribute.name + " " + as.content if !as.attribute.name.nil? && !as.content.nil?
          end
        end
      end
    end
    File.open("public/doccat/#{infobox_template.name}/train/doccat_train.txt", "w") { |file| file.write  str}
  end
  
  
  ##6
  def self.train_doccat
    infobox_template = InfoboxTemplate.where(name: "university").first
    
    `bin/opennlp DoccatTrainer -model public/doccat/#{infobox_template.name}/model/doccat.bin -lang en -data public/doccat/#{infobox_template.name}/train/doccat_train.txt -encoding UTF-8`
  end
  
  ##6.1 //// test
  def self.doccat_test_files
    infobox_template = InfoboxTemplate.where(name: "university").first
    
    #article = infobox_template.articles.first
    
    infobox_template.articles.where(for_test: 1).each do |article|
    
      `mkdir public/doccat/#{infobox_template.name}/test`
      
      if !File.directory?("public/doccat/#{infobox_template.name}/test/#{article.title.gsub(/[\s\&]/,'_')}")
      
        `mkdir public/doccat/#{infobox_template.name}/test/#{article.title.gsub(/[\s\&]/,'_')}`
        
        f = File.open("public/articles/#{infobox_template.name}/sentenced/test/#{article.title.gsub(/[\s\&]/,'_')}.txt")
        
        collection = {}
        #count = 0
        while(current_line = f.gets)
          File.open("public/sentence_tmp.txt", "w") { |file| file.write  current_line}
          command_result = `bin/opennlp Doccat public/doccat/#{infobox_template.name}/model/doccat.bin < public/sentence_tmp.txt`
          puts "##" + command_result + "##"
          
          attr = command_result.split(" ")[0]
          value = command_result.strip.gsub(/^[^\s]+\s/, '')
          
          if command_result.split(" ").count > 2        
            if !collection[attr].nil?
              collection[attr] << value
            else
              collection[attr] = []
              collection[attr] << value
            end
          end
          
          #puts collection[command_result.split(" ")[0]].count.to_s + value
          
          #count += 1
          #if count == 4
          #  break
          #end
          
        end
        
        #choose best one
        collection.map { |name,sentences|
          str = ""
          
          sentences.each {|s| str += s.strip + "\n"}
          
          File.open("public/doccat/#{infobox_template.name}/test/#{article.title.gsub(/[\s\&]/,'_')}/#{name.gsub(/[\s\/]+/,'_')}.txt", "w") { |file| file.write  str}
        }
        
      end
      
    end
    
  end
  
  
  ##6.2 ///test
  def self.filter
    infobox_template = InfoboxTemplate.where(name: "university").first
    
    article = infobox_template.articles.first
    
    infobox_template.attributes.each do |attribute|
      
      if attribute.name != "name" && attribute.name != "latin_name" && attribute.name != "native_name"
        begin
        
          cluster = ""
          File.open("public/cluster/#{infobox_template.name}/model/#{attribute.name.gsub(/[\s\/]+/,'_')}.bin") do |file|
            cluster = Marshal.load(file)
          end
          
          puts cluster.points.count
          
          infobox_template.articles.where(for_test: 1).each do |article|
            
              f = File.open("public/doccat/#{infobox_template.name}/test/#{article.title.gsub(/[\s\&]/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.txt")
              current_line = f.gets
              c_sentence = current_line
              
              cluster.points << current_line
              cluster.refresh_vocab
              max_similar = cluster.cosine(cluster.vector(current_line),cluster.vector(cluster.center))
              
              while(current_line = f.gets)
                similar = cluster.cosine(cluster.vector(current_line),cluster.vector(cluster.center))
                
                if similar > max_similar
                  max_similar = similar
                  c_sentence = current_line
                end
                
              end
              
              exsit = TestArticleAttributeSentence.where(article_id: article.id, attribute_id: attribute.id).first
              
              if exsit.nil?
                TestArticleAttributeSentence.create(article_id: article.id, attribute_id: attribute.id, sentence: c_sentence)
              else
                exsit.sentence = c_sentence
                exsit.save
              end
          
          end
          
        rescue
          puts "some error!!!!!!!!!!!!!!"
        end
      end
      
      
        
    end
    
    
  end
  
  ##7 gsub(/^([^\s]+\s){1}/,'') //// train
  def self.create_train_for_filter_by_cluster
    infobox_template = InfoboxTemplate.where(name: "university").first
    
    `mkdir public/cluster/#{infobox_template.name}/train`
    
    infobox_template.attributes.each do |attribute|
      str = ""
      f = File.open("public/doccat/#{infobox_template.name}/train/doccat_train.txt")
      while(current_line = f.gets)
        if !current_line.index('&lt;table') && !current_line.index('{') && !current_line.index('|')
          if /^([^\s]+\s){1}/.match(current_line)[1] == attribute.name+" "
            str += current_line.gsub(/^([^\s]+\s){1}/,'').strip+"\n"
          end
        end
      end
      File.open("public/cluster/#{infobox_template.name}/train/#{attribute.name.gsub(/[\s\/]+/,'_')}.txt", "w") { |file| file.write  str}
    end
    
  end
  
  ##8 ///train
  def self.create_vector_space_for_attribute   
    
    infobox_template = InfoboxTemplate.where(name: "university").first
    
    `mkdir public/cluster/#{infobox_template.name}/model`
    
    infobox_template.attributes.each do |attribute|
      puts attribute.attribute_sentences.count
      if attribute.name != "name" && attribute.name != "latin_name" && attribute.name != "native_name"
        data = []
        fn = "public/cluster/#{infobox_template.name}/train/#{attribute.name.gsub(/[\s\/]+/,'_')}.txt"
        
        f = File.open(fn)
         # Get all data
        while(current_line = f.gets)
          data.push current_line
        end
        puts "fgdfgd"+data.count.to_s
        
        if data.count > 0
          # Determine the number of clusters to find
          k = 1
          
          km = Kmeans.new
          # Run algorithm on data
          clusters = km.kmeans_fast(data, k)   
        
          clusters.each do |cluster|
            
            puts "dddd" + cluster.points.count.to_s + "################" + cluster.center
           
            File.open("public/cluster/#{infobox_template.name}/model/#{attribute.name.gsub(/[\s\/]+/,'_')}.bin",'w') do|file|
              Marshal.dump(cluster, file)
            end
    
          end
        end      
          
      end       
    end    
  end
  
  ##9 //// train
  def self.create_training_data_for_CRF
    x_window = 3;
    
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
        
        if as.article.for_test == 0
        
          content = as.content.gsub(/\|/,'')
          as.value = as.value.gsub(/\|/,'')
          
          parts = content.downcase.split(as.value.downcase)
          parts[0].split(/\s+/).each_with_index do |term,index|
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
          
          
          parts[1].split(/\s+/).each_with_index do |term,index|
            training_tr += term + " |5\n" if term.strip != "" if index < x_window + 1
            test_tr += term + " " if term.strip != "" if index < x_window + 1
          end
  
  
          training_tr += "\n"        
          test_tr += "\n"
        
        end
        
      end
      
      `mkdir public/crf/#{infobox_template.name}/data/#{attribute.name.gsub(/[\s\/]+/,'_')}`
      File.open("public/crf/#{infobox_template.name}/data/#{attribute.name.gsub(/[\s\/]+/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.train.tagged", "w") { |file| file.write  training_tr}
      #File.open("public/crf/#{infobox_template.name}/data/#{attribute.name.gsub(/[\s\/]+/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.test.tagged", "w") { |file| file.write  training_tr}
      #File.open("public/crf/#{infobox_template.name}/data/#{attribute.name.gsub(/[\s\/]+/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.test.raw", "w") { |file| file.write  test_tr}
    end
  end
  
  ##10 ---- from 6.1 6.2 //// test
  def self.create_test_files_crf
    #code
    infobox_template = InfoboxTemplate.where(name: "university").first
    
    article = infobox_template.articles.first
    
    
    
    
      infobox_template.attributes.each do |attribute|
        str = ""
        infobox_template.articles.where(for_test: 1).each do |article|
          test_s = TestArticleAttributeSentence.where(article_id: article.id, attribute_id: attribute.id).first
        
        
          
          if !test_s.nil?
            str += test_s.sentence.strip + "\n"
            #File.open("public/crf/#{infobox_template.name}/data/#{attribute.name.gsub(/[\s\/]+/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.test.raw", "w") { |file| file.write  test_s.sentence}
          end
        
        end
      
        File.open("public/crf/#{infobox_template.name}/data/#{attribute.name.gsub(/[\s\/]+/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.test.raw", "w") { |file| file.write  str } if str != ""
    
      end
    
    
  end
  
  
  ##11 //// train
  def self.training_CRF
    infobox_template = InfoboxTemplate.where(name: "university").first
    
    infobox_template.attributes.each do |attribute|
      puts `java -cp lib/colt.jar:lib/CRF.jar:lib/CRF-Trove_3.0.2.jar:lib/LBFGS.jar:build:. iitb.Segment.Segment train -f public/crf/#{infobox_template.name}/#{attribute.name.gsub(/[\s\/]+/,'_')}.conf`
      sleep(5)
    end
  end
  
  ##11 //// test
  def self.test_CRF
    infobox_template = InfoboxTemplate.where(name: "university").first
        
    infobox_template.attributes.each do |attribute|
      begin
        File.open("public/crf/#{infobox_template.name}/data/#{attribute.name.gsub(/[\s\/]+/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.test.raw")
        puts `java -cp lib/colt.jar:lib/CRF.jar:lib/CRF-Trove_3.0.2.jar:lib/LBFGS.jar:build:. iitb.Segment.Segment test -f public/crf/#{infobox_template.name}/#{attribute.name.gsub(/[\s\/]+/,'_')}.conf`
      rescue
        puts "some error!!!!!!!!!!!!!!"
      end
    end
    
  end
    
end
