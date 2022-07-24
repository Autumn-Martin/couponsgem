module Couponing::OfferSpecifics
  extend ActiveSupport::Concern

  def offer_list
    ""
  end
  def available_offers
    []
  end
end
