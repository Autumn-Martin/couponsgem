module Couponing::OfferSpecifics
  extend ActiveSupport::Concern

  included do
    has_many :offers, dependent: :destroy

    accepts_nested_attributes_for :offers, allow_destroy: true
  
    validates :offers, presence: true
  end

  def offer_list; end
  def available_offers
    []
  end
end
