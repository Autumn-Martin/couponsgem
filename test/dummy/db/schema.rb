# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20220704221232) do

  create_table "coupons", force: :cascade do |t|
    t.string   "name"
    t.string   "description"
    t.text     "metadata"
    t.string   "alpha_code"
    t.string   "alpha_mask"
    t.string   "digit_code"
    t.string   "digit_mask"
    t.string   "category_one"
    t.float    "amount_one",        default: 0.0
    t.float    "percentage_one",    default: 0.0
    t.string   "category_two"
    t.float    "amount_two",        default: 0.0
    t.float    "percentage_two",    default: 0.0
    t.date     "expiration"
    t.integer  "how_many",          default: 1
    t.integer  "redemptions_count", default: 0
    t.integer  "integer",           default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "coupons", ["alpha_code"], name: "index_coupons_on_alpha_code"
  add_index "coupons", ["digit_code"], name: "index_coupons_on_digit_code"
  
  create_table "offers", force: :cascade do |t|
    t.integer  "offerable_id",   null: false
    t.string   "offerable_type", null: false
    t.integer  "coupon_id",      null: false
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "offers", ["coupon_id"], name: "index_offers_on_coupon_id", using: :btree
  add_index "offers", ["offerable_type", "offerable_id"], name: "index_offers_on_offerable_type_and_offerable_id"

  create_table "redemptions", force: :cascade do |t|
    t.integer  "coupon_id"
    t.string   "user_id"
    t.string   "transaction_id"
    t.text     "metadata"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
