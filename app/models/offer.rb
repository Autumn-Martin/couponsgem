class Offer < ActiveRecord::Base
  belongs_to :offerable, polymorphic: true

  validates :code, presence: true
end
