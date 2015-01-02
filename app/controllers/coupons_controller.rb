require 'csv'
class CouponsController < ApplicationController
  
  def apply
    no_coupon = Coupon.no_coupon(params[:product_bag])
    respond_to do |wants|
      wants.js do
        begin
          response = Coupon.apply(params[:coupon_code], params[:product_bag])
        rescue CouponNotFound
          response = {"error" => "Coupon not found" }.merge(no_coupon)
        rescue CouponNotApplicable
          response = {"error" => "Coupon does not apply" }.merge(no_coupon)
        rescue CouponRanOut
          response = {"error" => "Coupon has run out"}.merge(no_coupon)
        rescue CouponExpired
          response = {"error" => "Coupon has expired"}.merge(no_coupon)
        end
        render :text => response.to_json
      end
    end    
  end
  
  def redeem
    respond_to do |wants|
      wants.js do
        Coupon.redeem(params[:coupon_code], params[:user_id], params[:tx_id], params[:metadata]).to_json
      end
    end
  end
  
  private
  
  
  def find_or_generate_coupon
      @coupon ||= Coupon.new
  end
end
