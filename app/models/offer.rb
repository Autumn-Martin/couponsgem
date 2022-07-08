class Offer < ActiveRecord::Base
  belongs_to :offerable, polymorphic: true

  include OfferSpecifics
  validates :code, presence: true
end
