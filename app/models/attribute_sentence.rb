class AttributeSentence < ActiveRecord::Base
  belongs_to :attribute
  belongs_to :article
end
