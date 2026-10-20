# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_10_20_140000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "alerts", force: :cascade do |t|
    t.bigint "brand_id", null: false
    t.bigint "store_id", null: false
    t.bigint "product_id", null: false
    t.bigint "opening_tracking_event_id", null: false
    t.bigint "confirming_tracking_event_id", null: false
    t.datetime "triggered_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["brand_id", "triggered_at"], name: "index_alerts_on_brand_id_and_triggered_at"
    t.index ["confirming_tracking_event_id"], name: "index_alerts_on_confirming_tracking_event_id", unique: true
    t.index ["opening_tracking_event_id"], name: "index_alerts_on_opening_tracking_event_id", unique: true
    t.index ["product_id"], name: "index_alerts_on_product_id"
    t.index ["store_id", "product_id"], name: "index_alerts_on_store_id_and_product_id"
    t.index ["triggered_at", "id"], name: "index_alerts_on_triggered_at_and_id"
  end

  create_table "brands", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "price_checks", force: :cascade do |t|
    t.decimal "price", precision: 10, scale: 2, null: false
    t.bigint "product_id", null: false
    t.bigint "store_id", null: false
    t.datetime "event_time", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "store_id", "event_time"], name: "index_price_checks_on_product_id_and_store_id_and_event_time"
    t.index ["store_id"], name: "index_price_checks_on_store_id"
    t.check_constraint "price >= 0::numeric", name: "price_checks_price_non_negative"
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.bigint "brand_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["brand_id"], name: "index_products_on_brand_id"
  end

  create_table "stores", force: :cascade do |t|
    t.string "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tracking_events", force: :cascade do |t|
    t.boolean "inventory_present"
    t.bigint "product_id", null: false
    t.bigint "store_id", null: false
    t.datetime "event_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "event_time", "id"], name: "index_tracking_events_on_product_id_and_event_time"
    t.index ["store_id", "event_time", "id"], name: "index_tracking_events_on_store_id_and_event_time"
    t.index ["store_id", "product_id", "event_time", "id"], name: "index_tracking_events_on_store_product_time"
  end

  add_foreign_key "alerts", "brands"
  add_foreign_key "alerts", "products"
  add_foreign_key "alerts", "stores"
  add_foreign_key "alerts", "tracking_events", column: "confirming_tracking_event_id"
  add_foreign_key "alerts", "tracking_events", column: "opening_tracking_event_id"
  add_foreign_key "price_checks", "products"
  add_foreign_key "price_checks", "stores"
  add_foreign_key "products", "brands"
  add_foreign_key "tracking_events", "products"
  add_foreign_key "tracking_events", "stores"
end
