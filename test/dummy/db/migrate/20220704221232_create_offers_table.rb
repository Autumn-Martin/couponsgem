class CreateOffersTable < ActiveRecord::Migration
  def change
    create_table :offers do |t|
      t.references :offerable, polymorphic: true, index: true, null: false
      t.references :coupon, index: true, null: false

      t.timestamps null: false
    end
  end
end
