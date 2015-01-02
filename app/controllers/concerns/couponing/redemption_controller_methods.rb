module Couponing
  module RedemptionControllerMethods

    def apply
      no_coupon = Coupon.no_coupon(product_bag)
      respond_to do |format|
        format.js do
          begin
            response = Coupon.apply(params[:coupon_code], product_bag)
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

    # This is where you load the hash from the object you wish to discount
    # def product_bag
    #   @product.coupon_hash
    # end

  end
end