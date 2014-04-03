class TestArticleAttributeSentence < ActiveRecord::Base
  
  belongs_to :article
  belongs_to :attribute
end
