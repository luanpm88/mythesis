class AttributeValue < ActiveRecord::Base
  belongs_to :article
  belongs_to :attribute
end
