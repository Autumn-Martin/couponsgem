require 'errors'


class Coupon < ActiveRecord::Base
  include Couponing::OfferSpecifics
  has_many :redemptions

  validates :name, :presence => true

  validates :description, :presence => true
  validates :expiration, :presence => true
  validates :how_many, :presence => true, :numericality => true
  validate do |coupon|
    errors.add(:how_many, "must be positive") unless coupon.how_many > 0
  end

  validates :category_one, :presence => true
  validates :amount_one, :presence => true, :numericality => true
  validates :percentage_one, :presence => true, :numericality => true

  validates :amount_two, :numericality => true
  validates :percentage_two, :numericality => true
  
  # Check to see if, given the size of the mask and the number of requested coupons
  # see if it is possible to generate that many coupons. Raise an error otherwise
  def self.enough_space?(alpha_mask, digit_mask, number_requested)
    alpha_size = alpha_mask.gsub(/[^\w]/, '').size
    digit_size = digit_mask.gsub(/[^\w]/, '').size
    if number_requested > 26 ** alpha_size || number_requested > 10 ** digit_size
      false
    else
      true
    end
  end
  
  
  validates :alpha_mask, :presence => true, :format => {:with => /\A[a-zA-Z]+(-[a-zA-Z]+)*\z/}
  validates :digit_mask, :presence => true, :format => {:with => /\A\d+(-\d+)*\z/}
  
  before_create do
    self.digit_code = generate_digit_code
    self.alpha_code = generate_alpha_code.upcase
  end

  before_update do
    self.alpha_code = self.alpha_code ? self.alpha_code.upcase : nil
  end
  
  scope :not_expired, lambda {
    where(["expiration >= ?", Time.now])
  }
  
  scope :not_used_up, lambda {
    where("coupons.redemptions_count < coupons.how_many")
  }
  
  scope :with_code, lambda { |code| 
    stripped = code.gsub(/[^\w]/, '')
    where(["alpha_code = ? OR digit_code = ?", stripped, stripped]).
    limit(1)
  }
  
  scope :for_category, lambda { |category|
    where(["category = ?", category])
  }
  
  # Given a category, if that category matches any of this coupons categories,
  # compute the savings. 
  #
  # We apply the fixed amount first before applying the percentage discount
  # 
  # We also don't let the savings exceed the initial cost
  def savings(category, cost)
    if category == category_one
      if cost < amount_one
        cost
      else
        cost - ((cost - amount_one) * (1.0 - (percentage_one.to_f/100.to_f))) 
      end
    elsif category == category_two
      if cost < amount_two
        cost
      else
        cost - ((cost - amount_two) * (1.0 - (percentage_two.to_f/100.to_f)))
      end
    else
      0
    end
  end
  
  # Generate a hash similar to what #apply returns, except there is
  # no savings. 
  def self.no_coupon(product_bag = {})
    r = {:savings => 0.0, :grand_total => 0.0}
    product_bag.each do |category, price|
      price = Float(price)
      r[:grand_total] += price
      r[category] = price
    end
    round_values(r)
  end
    
  # Apply a coupon (or throw an exception if the coupon is not valid)
  # Return a hash with the new prices for each product, as well the grand total
  # and total savings
  def self.apply(coupon_code, offer_code, product_bag = {})
    return_hash = {}
    coupon = find_coupon(coupon_code, offer_code)
    product_bag.each do |category, price|
      price = Float(price)
      category_hash = return_hash[category] = {
        "original_price" => price, 
        "savings" => 0.0,
        "grand_total" => price
      }
      if coupon
        savings = coupon.savings(category, price)
        category_hash["savings"] += savings
        category_hash["grand_total"] -= savings
      end
    end
    return_hash
  end

  def to_csv
    [self.name, self.description, self.alpha_code, self.alpha_mask, self.digit_code, self.digit_mask, self.category_one, self.amount_one, self.percentage_one, self.category_two, self.amount_two, self.percentage_two, self.expiration, self.how_many, self.redemptions_count]
  end

  def can_edit?
    self.redemptions.empty?
  end

  def update_coupon_offers(coupon, offer_codes)
    Coupon.transaction do
      self.update_offers(offer_codes)
      self.update(coupon)
    end
  end

  def update_offers(codes)
    existing_offers = self.offers.select(:id,:code)
    existing_codes = existing_offers.pluck(:code)

    updated_codes = codes.select(&:present?)
    added_codes = updated_codes - existing_codes
    removed_codes = existing_codes - updated_codes
    
    existing_offers.where(code: existing_codes - updated_codes).destroy_all
    added_codes.map {|code| self.offers << Offer.new(code: code) }
  end
   
  private
  
  # find the coupon, or raise an exception if that coupon is not valid
  def self.find_coupon(coupon_code, offer_code, user_id = nil)
    coupon = Coupon.with_code(coupon_code.upcase).first
    raise CouponNotFound if coupon.nil?
    if user_id && coupon.redemptions.find_by_user_id(user_id)
      raise CouponAlreadyRedeemedByUser
    end
    raise CouponRanOut if coupon.redemptions_count >= coupon.how_many
    raise CouponExpired if coupon.expiration < Time.now.to_date
    # Allows generic coupons that were made prior to specificity requirement to still work
    raise CouponNotApplicable if coupon.offers.present? && !coupon.offers.pluck(:code).include?(offer_code)
    return coupon
  end
   
  def generate_alpha_code
    string_pool =  [('A'..'Z')].map{|i| i.to_a}.flatten
    string  =  (1..alpha_mask.gsub(/-/,'').size).map{ string_pool[rand(string_pool.length)]  }.join

    while Coupon.find_by_alpha_code(string)
      string = (1..alpha_mask.gsub(/-/,'').size).map{ string_pool[rand(string_pool.length)]  }.join
    end

    return string
  end
  
  def generate_digit_code
    digit_pool = [(0..9)].map{|i| i.to_a}.flatten
    digit = (1..digit_mask.gsub(/-/,'').size).map{ digit_pool[rand(digit_pool.length)]  }.join
    
    while Coupon.find_by_digit_code(digit)
      digit = (1..digit_mask.gsub(/-/,'').size).map{ digit_pool[rand(digit_pool.length)]  }.join
    end
    
    return digit
  end
    
  def self.round_values(hash)
    hash.each do |k,v|
      hash[k] = v.round(2) if v.is_a?(Float)
    end
    hash
  end
  
end

