class CreateOffersTable < ActiveRecord::Migration
  def change
    create_table :offers do |t|
      t.string :code, limit: 255
      t.references :offerable, polymorphic: true, index: true, null: false

      t.timestamps null: false
    end
  end
end
