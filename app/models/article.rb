class Article < ActiveRecord::Base
  validates :title, presence: true, uniqueness: true
  
  belongs_to :infobox_template
  has_many :attribute_sentences
  has_many :attribute_values
  has_many :test_article_attribute_sentences
  
  
  ##1
  def self.import(maxxx)
    #infobox template
    infobox_template = InfoboxTemplate.where(name: "university").first
    
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
    
    count_articles = (Article.count/2).to_i
    
    Article.update_all("for_test=0","id <= "+count_articles.to_s)
    Article.update_all("for_test=1","id > "+count_articles.to_s)
    
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
            else
              f = File.open("public/articles/university/sentenced/test/#{attribute_value.article.title.gsub(/[\s\&]/,'_')}.txt")
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
        attribute.attribute_sentences.where(for_test: 0).each do |as|
          str += as.attribute.name + " " + as.content if !as.attribute.name.nil? && !as.content.nil?
        end
      end
    end
    File.open("public/doccat/#{infobox_template.name}/train/doccat_train.txt", "w") { |file| file.write  str}
  end
  
  
  ##6
  def self.train_doccat
    infobox_template = InfoboxTemplate.where(name: "university").first
    
    `mkdir public/doccat/#{infobox_template.name}/model`
    
    `bin/opennlp DoccatTrainer -model public/doccat/#{infobox_template.name}/model/doccat.bin -lang en -data public/doccat/#{infobox_template.name}/train/doccat_train.txt -encoding UTF-8`
  end
  
  ##6.1 //// test
  def self.doccat_test_files
    infobox_template = InfoboxTemplate.where(name: "university").first
    
    #article = infobox_template.articles.first
    
    `mkdir public/doccat/#{infobox_template.name}/test`
    puts infobox_template.articles.where(for_test: 1).count
    infobox_template.articles.where(for_test: 1).each do |article|
          
      
      #if !File.directory?("public/doccat/#{infobox_template.name}/test/#{article.title.gsub(/[\s\&]/,'_')}")
      
        `mkdir public/doccat/#{infobox_template.name}/test/#{article.title.gsub(/[\s\&]/,'_')}`
        
        `java -jar bin/DoccatRun.jar public/doccat/#{infobox_template.name}/model/doccat.bin public/articles/#{infobox_template.name}/sentenced/test/#{article.title.gsub(/[\s\&]/,'_')}.txt public/doccat/#{infobox_template.name}/test/#{article.title.gsub(/[\s\&]/,'_')}/all.txt`
        
        f = File.open("public/doccat/#{infobox_template.name}/test/#{article.title.gsub(/[\s\&]/,'_')}/all.txt")
        
        
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
          
          File.open("public/doccat/#{infobox_template.name}/test/#{article.title.gsub(/[\s\&]/,'_')}/#{name.gsub(/[\s\/]+/,'_')}.txt", "w") { |file| file.write  str}
        }
        
      #  f = File.open("public/articles/#{infobox_template.name}/sentenced/test/#{article.title.gsub(/[\s\&]/,'_')}.txt")
      #  puts "public/articles/#{infobox_template.name}/sentenced/test/#{article.title.gsub(/[\s\&]/,'_')}.txt"
      #  collection = {}
      #  #count = 0
      #  while(current_line = f.gets)
      #    File.open("public/sentence_tmp.txt", "w") { |file| file.write  current_line}
      #    command_result = `bin/opennlp Doccat public/doccat/#{infobox_template.name}/model/doccat.bin < public/sentence_tmp.txt`
      #    puts "##" + command_result + "##"
      #    
      #    attr = command_result.split(" ")[0]
      #    value = command_result.strip.gsub(/^[^\s]+\s/, '')
      #    
      #    if command_result.split(" ").count > 2        
      #      if !collection[attr].nil?
      #        collection[attr] << value
      #      else
      #        collection[attr] = []
      #        collection[attr] << value
      #      end
      #    end
      #    
      #
      #    
      #    #count += 1
      #    #if count == 4
      #    #  break
      #    #end
      #    
      #  end
      #  
      #  #choose best one
      #  collection.map { |name,sentences|
      #    str = ""
      #    
      #    sentences.each {|s| str += s.strip + "\n"}
      #    
      #    File.open("public/doccat/#{infobox_template.name}/test/#{article.title.gsub(/[\s\&]/,'_')}/#{name.gsub(/[\s\/]+/,'_')}.txt", "w") { |file| file.write  str}
      #  }
      #  
      ##end
      
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
              current_line = f.gets.strip
              c_sentence = current_line
              
              cluster.points << current_line
              cluster.refresh_vocab
              max_similar = cluster.cosine(cluster.vector(current_line),cluster.vector(cluster.center))
              
              while(current_line = f.gets)
                puts current_line
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
    
    `mkdir public/cluster/#{infobox_template.name}`
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
      attribute.attribute_sentences.where(for_test: 0).each do |as|
        
        
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
        
          puts test_s.sentence if !test_s.nil?
          
          if !test_s.nil?
            str += test_s.sentence + "\n"
            #File.open("public/crf/#{infobox_template.name}/data/#{attribute.name.gsub(/[\s\/]+/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.test.raw", "w") { |file| file.write  test_s.sentence}
          end
        
        end
        puts str
        File.open("public/crf/#{infobox_template.name}/data/#{attribute.name.gsub(/[\s\/]+/,'_')}/#{attribute.name.gsub(/[\s\/]+/,'_')}.test.raw", "w") { |file| file.write  str } if str != ""
      end
    
    
  end
  
  
  ##11 //// train
  def self.training_CRF
    infobox_template = InfoboxTemplate.where(name: "university").first
    
    infobox_template.attributes.each do |attribute|
      puts `java -cp lib/colt.jar:lib/CRF.jar:lib/CRF-Trove_3.0.2.jar:lib/LBFGS.jar:build:. iitb.Segment.Segment train -f public/crf/#{infobox_template.name}/#{attribute.name.gsub(/[\s\/]+/,'_')}.conf`
    end
  end
  
  ##12 //// test
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
  
  ##13
  def self.get_result
    infobox_template = InfoboxTemplate.where(name: "university").first
    
    infobox_template.attributes.each do |attribute|
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
            
            sentence += current_line.gsub(/\|[12345]/,'').strip + " "
          else
            current_line_draw = f_raw.gets
            taas = TestArticleAttributeSentence.where(sentence: current_line_draw).first
            
            if !taas.nil?
              if (count2 == 1 && count3 > 1 && count4 == 1) || (count2 == 1 && count3 == 0 && count4 == 1) || (count2 == 1 && count3 == 0 && count4 == 0)
                puts value + ": " + attribute.name
                
                taas.test_value = value.strip              
              else
                taas.test_value = nil
              end
              
              taas.save
            end
            
              
            
            puts "###"+sentence #TestArticleAttributeSentence.where(sentence: current_line_draw).count
            puts current_line_draw + "#####"
            
            puts TestArticleAttributeSentence.where(sentence: current_line_draw).count
            
            sentence = '';
            value = '';
            count2 = 0;
            count3 = 0;
            count4 = 0;
          end
          
          
          #count result
          str = ""
          count_t = 0;
          count_finded = 0;
          TestArticleAttributeSentence.all.each do |test|
            
            attribute_value = AttributeValue.where(article_id: test.article.id, attribute_id: test.attribute.id).first
            
            if !attribute_value.nil? && !test.test_value.nil?
              puts attribute_value.raw_value            
              str += test.test_value + " |......| " + attribute_value.raw_value + "\n"
              
              if test.test_value.strip.downcase == attribute_value.raw_value.strip.downcase
                count_t += 1;
              end
              
              count_finded += 1;
              
            end
          end
          
          total = AttributeSentence.where(for_test: 1).count("CONCAT(article_id,'---',attribute_id)",distinct: true).to_s
          first_line = "Finded: " + count_finded.to_s + "\n"
          first_line += "Correct: " + count_t.to_s + "\n"
          first_line += "Total: " + total + "\n\n\n"
          File.open("public/crf/result_p.txt", "w") { |file| file.write  first_line + str}
          
        end
      end
    end
    
    
    
  end
  
  def self.run_all
    
    ###1
    self.import(1697)
    #
    ###3
    self.write_article_to_files
    #
    ###4
    self.find_sentences_with_value
    #
    ###5
    self.create_doccat_training_file
    #
    ###6
    self.train_doccat
    #
    ###7
    self.create_train_for_filter_by_cluster
    #
    ###8
    self.create_vector_space_for_attribute
    #
    ###9
    self.create_training_data_for_CRF
    #
    ###6.1
    self.doccat_test_files
    #
    ###6.2
    self.filter
    #
    ###10
    self.create_test_files_crf
    
    ##11
    self.training_CRF
    
    ##12
    self.test_CRF
    
    ##13
    self.get_result
  end
    
end
