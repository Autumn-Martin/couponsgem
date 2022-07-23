module Couponing
  module CrudControllerMethods

    def new
      @coupon = Coupon.new
    end

    def index
      require "csv"

      @coupons = Coupon
      @coupons = @coupons.where(["id >= ?", params[:after]]) if params[:after]
      @coupons = @coupons.all

      respond_to do |format|
        format.html
        format.csv do
          csv_string = CSV.generate(:force_quotes => true) do |csv| 
            csv << ["name","description", "alpha_code", "alpha_mask", "digit_code", "digit_mask", "category_one", "amount_one", "percentage_one", "category_two", "amount_two", "percentage_two", "expiration", "how_many", "redemptions_count", "offer_list"]
            @coupons.each do |c|
              row = c.to_csv << c.offer_list
              csv << row
            end
          end
          send_data csv_string, :type => "text/plain",  :filename=>"coupons.csv", :disposition => 'attachment'
        end
      end
    end

    def create
      respond_to do |format|
        format.html do
          @coupon = Coupon.new coupon_params
          num_requested = params[:num_requested].blank? ? 1 : params[:num_requested]

          unless Coupon.enough_space?(@coupon.alpha_mask, @coupon.digit_mask, Integer(num_requested))
            @coupon.errors.add(:alpha_mask, " Alpha/digit mask is not long enough")
            @coupon.errors.add(:digit_mask, " Alpha/digit mask is not long enough")
          end
          if Integer(num_requested) < 0
            @coupon.errors.add(:base, "How many must be positive")
            flash[:coupon_error] = "How many must be positive"
          end
          if @coupon.errors.empty? && @coupon.valid?
            create_count = 0
            Integer(num_requested).times do |i|
              coupon = Coupon.new(coupon_params)
              if coupon.save
                @first_coupon ||= coupon.id
                create_count += 1
              end
            end
            flash[:coupon_notice] = "Created #{create_count} coupons"
            redirect_to coupon_redirect_path(after: @first_coupon)
          else
            flash[:coupon_error] ||= 'Please fix the errors below'
            render :action => "new"
          end
        end
      end
    end

    def edit
      load_coupon
    end

    def update
      load_coupon

      if @coupon.update coupon_params
        redirect_to coupon_redirect_path(after: @first_coupon)
      else
        render action: "edit"
      end
    end

    protected

    def load_coupon
      @coupon = Coupon.find params[:id]
      raise ActiveRecord::RecordNotFound unless @coupon.can_edit?
    end

    def coupon_params
      params.require(:coupon).permit(
        :name, 
        :description,
        :how_many,
        :alpha_mask,
        :alpha_code,
        :digit_mask,
        :digit_code,
        :category_one,
        :amount_one,
        :percentage_one,
        :category_two,
        :amount_two,
        :percentage_two,
        :expiration,
        offers_attributes: [:_destroy, :id, :offerable_id, :offerable_type]
      )
    end
  end
end
