class Offer < ActiveRecord::Base
  belongs_to :offerable, polymorphic: true
  belongs_to :coupon
end
