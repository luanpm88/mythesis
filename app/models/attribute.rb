class Attribute < ActiveRecord::Base
  validates :name, presence: true, uniqueness: true
  
  belongs_to :infobox_template
  
  has_many :attribute_values
  has_many :attribute_sentences
  has_many :test_article_attribute_sentences
end
