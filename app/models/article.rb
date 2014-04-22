class Article < ActiveRecord::Base
  validates :title, presence: true, uniqueness: true
  
  belongs_to :infobox_template
  has_many :attribute_sentences
  has_many :attribute_values
  has_many :test_article_attribute_sentences
  
  @@template = 'actor'
  @@no_attributes = ['name','image','caption','imagesize','bgcolour','alt','latin_name','native_name','image_size']
  
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
                            
                            val = /\{\{infobox\s*#{infobox_template.name}(.+)((.*)(\{\{(.+)\}\})(.*))*\}\}/m.match(content.downcase)
                            if !val.nil?
                              
                              
                              Article.create(:title => page.css("title").text,
                                             :content => page.css("text").text,
                                             :content_html => Wikitext::Parser.new.parse(page.css("text").text.gsub(/\[\[\s*category\:[^\[\]]+\]\]/mi, '')),
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
    
    count_articles = (Article.count/2).to_i
    
    Article.update_all("for_test=0","id <= "+count_articles.to_s)
    Article.update_all("for_test=1","id > "+count_articles.to_s)
    
    
  end


  ##1.1
  def self.set_attribute_status
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    infobox_template.attributes.each do |attribute|
      count = AttributeValue.joins(:article).where(attribute_id: attribute.id).where("articles.for_test=0").count("article_id",distinct: true) #AttributeValue.where(attribute_id: attribute.id).count("article_id",distinct: true)
      total = infobox_template.articles.where(for_test: 0).count
      
      puts count.to_s + "/" + total.to_s
      sleep(1)
      
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
      #av.save
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
    `mkdir public/articles/#{infobox_template.name}`
    `mkdir public/articles/#{infobox_template.name}/sentenced`
    `mkdir public/articles/#{infobox_template.name}/sentenced/train`
    `mkdir public/articles/#{infobox_template.name}/sentenced/test`
    
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
        File.open("public/articles/#{infobox_template.name}/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt", "w") { |file| file.write content_fixed }
      rescue
        puts "some error"
      end
      
      system("bin/opennlp SentenceDetector en-sent.bin < public/articles/#{infobox_template.name}/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt > public/articles/#{infobox_template.name}/sentenced/#{for_d}/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt")
    end

  end
  
  
  ##4
  def self.find_sentences_with_value
    infobox_template = InfoboxTemplate.where(name: @@template).first
    infobox_template.attributes.where(status: 1).all.each do |attribute|
      
      #if attribute.name != "name"
        attribute.attribute_values.each do |attribute_value|
          
          begin
            if attribute_value.article.for_test == 0
              f = File.open("public/articles/#{@@template}/sentenced/train/#{attribute_value.article.title.gsub(/[\s\&\'\,\)\(\"]/,'_')}.txt")
            else
              f = File.open("public/articles/#{@@template}/sentenced/test/#{attribute_value.article.title.gsub(/[\s\&\'\,\)\(\"]/,'_')}.txt")
            end
            
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
                  if attribute_value.article.for_test == 0
                    as.for_test = 0
                  else
                    as.for_test = 1
                  end
                  as.save
                end
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
  
  
  ##5
  def self.create_doccat_training_file
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    `mkdir public/doccat/#{infobox_template.name}`
    `mkdir public/doccat/#{infobox_template.name}/train`
    
    str = ""
    
    infobox_template.attributes.where(status: 1).each do |attribute|
      if attribute.name != "name" && attribute.name != "latin_name" && attribute.name != "native_name" && attribute.name != "image_size"
        attribute.attribute_sentences.where(for_test: 0).each do |as|
          str += as.attribute.name + " " + as.content if !as.attribute.name.nil? && !as.content.nil?
        end
      end
    end
    File.open("public/doccat/#{infobox_template.name}/train/doccat_train.txt", "w") { |file| file.write  str}
  end
  
  
  ##6
  def self.train_doccat
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    `mkdir public/doccat/#{infobox_template.name}/model`
    
    `bin/opennlp DoccatTrainer -model public/doccat/#{infobox_template.name}/model/doccat.bin -lang en -data public/doccat/#{infobox_template.name}/train/doccat_train.txt -encoding UTF-8`
  end
  
  ##6.1 //// test
  def self.doccat_test_files
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    #article = infobox_template.articles.first
    
    `mkdir public/doccat/#{infobox_template.name}/test`
    puts infobox_template.articles.where(for_test: 1).count
    infobox_template.articles.where(for_test: 1).each do |article|
          
      
      #if !File.directory?("public/doccat/#{infobox_template.name}/test/#{article.title.gsub(/[\s\&]/,'_')}")
      
        `mkdir public/doccat/#{infobox_template.name}/test/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}`
        
        `java -jar bin/DoccatRun.jar public/doccat/#{infobox_template.name}/model/doccat.bin public/articles/#{infobox_template.name}/sentenced/test/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}.txt public/doccat/#{infobox_template.name}/test/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}/all.txt`
        
        begin
        
          f = File.open("public/doccat/#{infobox_template.name}/test/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}/all.txt")
          
          
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
              File.open("public/doccat/#{infobox_template.name}/test/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}/#{name.gsub(/[\s\/]+/,'_')}.txt", "w") { |file| file.write  str}
            rescue
              puts "some error"
            end
          }
        
        rescue
          puts "read article error"        
        end     
    end
    
  end
  
  
  ##6.2 ///test
  def self.filter
    #TestArticleAttributeSentence.delete_all
    
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    article = infobox_template.articles.first
    
    infobox_template.attributes.where(status: 1).each do |attribute|
      
      if attribute.name != "name" && attribute.name != "latin_name" && attribute.name != "native_name" && attribute.name != "image_size"
        if File.file?("public/cluster/#{infobox_template.name}/model/#{attribute.name.gsub(/[\s\/]+/,'_')}.bin")
        
          cluster = ""
          
          
         
          infobox_template.articles.where(for_test: 1).each do |article|
            
            exsit = TestArticleAttributeSentence.where(article_id: article.id, attribute_id: attribute.id).first
            if exsit.nil?
              #puts "not exsit!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
              
              if File.file?("public/doccat/#{infobox_template.name}/test/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.txt")
                
                File.open("public/cluster/#{infobox_template.name}/model/#{attribute.name.gsub(/[\s\/]+/,'_')}.bin") do |file|
                  cluster = Marshal.load(file)
                end
                
                
                
                
                
                f = File.open("public/doccat/#{infobox_template.name}/test/#{article.title.gsub(/[\s\&\'\,\)\(\"\:\/]/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.txt")
                current_line = f.gets.strip
                c_sentence = current_line
                
                
                #cluster.points << current_line
                #cluster.refresh_vocab
                #cluster.get_centroid
                puts current_line
                max_similar = 0
                
                count = 0
                while(current_line = f.gets)
                  count += 1
                  
                  puts count
                  
                  similar = cluster.cosine(cluster.vector(cluster.clean_vocab(current_line)), cluster.centroid)
                  
                  if similar > max_similar
                    max_similar = similar
                    c_sentence = current_line
                  end
                  
                end
                
                puts max_similar

                
                exsit = TestArticleAttributeSentence.where(article_id: article.id, attribute_id: attribute.id).first
                
                if exsit.nil?
                  TestArticleAttributeSentence.create(article_id: article.id, attribute_id: attribute.id, sentence: c_sentence)
                else
                  exsit.sentence = c_sentence
                  exsit.save
                end
              
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
    
    `mkdir public/cluster/#{infobox_template.name}`
    `mkdir public/cluster/#{infobox_template.name}/train`
    
    infobox_template.attributes.where(status: 1).each do |attribute|
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
    
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    `mkdir public/cluster/#{infobox_template.name}/model`
    
    infobox_template.attributes.where(status: 1).each do |attribute|
      puts attribute.attribute_sentences.count
      if attribute.name != "name" && attribute.name != "latin_name" && attribute.name != "native_name" && attribute.name != "image_size"
        data = []
        fn = "public/cluster/#{infobox_template.name}/train/#{attribute.name.gsub(/[\s\/]+/,'_')}.txt"
        
        f = File.open(fn)
         # Get all data
        while(current_line = f.gets)
          data.push current_line
          puts current_line
        end
        puts "fgdfgd"+data.count.to_s
        
        if data.count > 0
          # Determine the number of clusters to find
          k = 1
          
          km = Kmeans.new
          # Run algorithm on data
          clusters = km.kmeans_fast(data, k)
          
          #puts clusters.first.centroid
          
        
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
    
    infobox_template = InfoboxTemplate.where(name: @@template).first
    `mkdir public/crf/#{infobox_template.name}`
    `mkdir public/crf/#{infobox_template.name}/data`
    
    str = "";
    infobox_template.attributes.where(status: 1).each do |attribute|
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
      attribute.attribute_sentences.where(for_test: 0).each do |as|
        
        
          content = as.content.gsub(/\|/,'').gsub('<', ' <').gsub('>', '> ')
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
      
      `mkdir public/crf/#{infobox_template.name}/data/#{attribute.name.gsub(/[\s\/]+/,'_')}`
      File.open("public/crf/#{infobox_template.name}/data/#{attribute.name.gsub(/[\s\/]+/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.train.tagged", "w") { |file| file.write  training_tr}
      #File.open("public/crf/#{infobox_template.name}/data/#{attribute.name.gsub(/[\s\/]+/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.test.tagged", "w") { |file| file.write  training_tr}
      #File.open("public/crf/#{infobox_template.name}/data/#{attribute.name.gsub(/[\s\/]+/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.test.raw", "w") { |file| file.write  test_tr}
    end
  end
  
  ##10 ---- from 6.1 6.2 //// test
  def self.create_test_files_crf
    #code
    infobox_template = InfoboxTemplate.where(name: @@template).first

    
      infobox_template.attributes.where(status: 1).each do |attribute|
        str = ""
        infobox_template.articles.where(for_test: 1).each do |article|
          test_s = TestArticleAttributeSentence.where(article_id: article.id, attribute_id: attribute.id).first
        
          puts test_s.sentence if !test_s.nil?
          
          if !test_s.nil?
            str += test_s.sentence.gsub('<', ' <').gsub('>', '> ') + "\n"
            #File.open("public/crf/#{infobox_template.name}/data/#{attribute.name.gsub(/[\s\/]+/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.test.raw", "w") { |file| file.write  test_s.sentence}
          end
        
        end
        puts str
        File.open("public/crf/#{infobox_template.name}/data/#{attribute.name.gsub(/[\s\/]+/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.test.raw", "w") { |file| file.write  str } if str != ""
      end
    
    
  end
  
  
  ##11 //// train
  def self.training_CRF
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    infobox_template.attributes.where(status: 1).each do |attribute|
      puts `java -cp lib/colt.jar:lib/CRF.jar:lib/CRF-Trove_3.0.2.jar:lib/LBFGS.jar:build:. iitb.Segment.Segment train -f public/crf/#{infobox_template.name}/#{attribute.name.gsub(/[\s\/]+/,'_')}.conf`
    end
  end
  
  ##12 //// test
  def self.test_CRF
    infobox_template = InfoboxTemplate.where(name: @@template).first
        
    infobox_template.attributes.where(status: 1).each do |attribute|
      begin
        File.open("public/crf/#{infobox_template.name}/data/#{attribute.name.gsub(/[\s\/]+/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.test.raw")
        puts `java -cp lib/colt.jar:lib/CRF.jar:lib/CRF-Trove_3.0.2.jar:lib/LBFGS.jar:build:. iitb.Segment.Segment test -f public/crf/#{infobox_template.name}/#{attribute.name.gsub(/[\s\/]+/,'_')}.conf`
      rescue
        puts "some error!!!!!!!!!!!!!!"
      end
    end
    
  end
  
  ##13
  def self.get_result
    infobox_template = InfoboxTemplate.where(name: @@template).first
    
    infobox_template.attributes.where(status: 1).each do |attribute|
      file_name = "public/crf/#{infobox_template.name}/out/#{attribute.name.gsub(/[\s\/]+/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.test.tagged"
      file_name_raw = "public/crf/#{infobox_template.name}/data/#{attribute.name.gsub(/[\s\/]+/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.test.raw"
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
              value += current_line.gsub(/\|[12345]/,'').strip + " "              
            end
            
            if current_line.index('|3')
              count3 += 1
              value += current_line.gsub(/\|[12345]/,'').strip + " "
            end
            
            if current_line.index('|4')
              count4 += 1
              value += current_line.gsub(/\|[12345]/,'').strip + " "
            end

          else
            current_line_draw = f_raw.gets
            taas = TestArticleAttributeSentence.where(sentence: current_line_draw.strip).first
            puts taas.nil?
            
            if !taas.nil?
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
  
  ##14
  def self.write_result
    infobox_template = InfoboxTemplate.where(name: @@template).first
      
      #count result
      str = ""
      count_t = 0;
      count_finded = 0;
      
      infobox_template.articles.where(for_test: 1).each do |article|
        puts article.id

          
          
          article.test_article_attribute_sentences.each do |test|
            
            attribute_sentence = AttributeSentence.where(article_id: test.article_id, attribute_id: test.attribute_id).first
            puts test.test_value

            #puts test.test_value = "#########"
            
            if !attribute_sentence.nil? && !test.test_value.nil?                         
                            
              attribute_value = AttributeValue.where(article_id: test.article_id, attribute_id: test.attribute_id).first
              str += test.test_value + " |......| " + attribute_value.raw_value + "\n"
              puts attribute_value.raw_value
              
              if test.test_value.strip.downcase == attribute_value.raw_value.strip.downcase
                count_t += 1;
              end
              
            end
            count_finded += 1;
          end
          
    end
      
    total = AttributeSentence.where(for_test: 1).count("CONCAT(article_id,'---',attribute_id)",distinct: true).to_s
    first_line = "Found: " + count_finded.to_s + "\n"
    first_line += "Correct: " + count_t.to_s + "\n"
    first_line += "Total: " + total + "\n\n\n"
    File.open("public/crf/result_p.txt", "w") { |file| file.write  first_line + str}
  end
  
  def self.run_all
    
    ####1
    #self.import(312)
    #self.write_log("#####1")
    #
    ####1.1
    #self.set_attribute_status
    #self.write_log("#####2")
    ##
    ####2
    #self.create_raw_attribute_value
    ##
    ####3
    #self.write_article_to_files
    #self.write_log("#####3")
    ##
    ####4
    #self.find_sentences_with_value
    #self.write_log("#####4")
    ##
    ####5
    #self.create_doccat_training_file
    #self.write_log("#####5")
    ##
    ####6
    #self.train_doccat
    #self.write_log("#####6")
    ##
    ####7
    #self.create_train_for_filter_by_cluster
    #self.write_log("#####7")
    #
    ####8
    #self.create_vector_space_for_attribute
    #
    #self.write_log("#####8")
    ##
    ####9
    #self.create_training_data_for_CRF
    #self.write_log("#####9")
    ##
    ####6.1
    #self.doccat_test_files
    #self.write_log("#####6.1")
    
    ####6.2
    #self.filter
    #self.write_log("#####6.2")
    #
    ###10
    self.create_test_files_crf
    self.write_log("#####10")
    
    ##11
    self.training_CRF
    self.write_log("#####11")
    
    ##12
    self.test_CRF
    self.write_log("#####12")
    
    ##13
    self.get_result
    self.write_log("#####13")
    
    ##14
    self.write_result
    self.write_log("#####14")
    
  end
  
  
    
end
