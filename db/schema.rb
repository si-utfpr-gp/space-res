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

ActiveRecord::Schema[8.1].define(version: 2026_11_12_133836) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "buildings", force: :cascade do |t|
    t.integer "campus_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campus_id", "name"], name: "index_buildings_on_campus_id_and_name", unique: true
  end

  create_table "campi", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_campi_on_name", unique: true
  end

  create_table "departments", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_departments_on_name", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "token"
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "spaces", force: :cascade do |t|
    t.integer "campus_id", null: false
    t.integer "building_id"
    t.integer "department_id"
    t.integer "usage_term_id"
    t.string "name", null: false
    t.text "description"
    t.boolean "requires_approval", default: false, null: false
    t.string "status", default: "available", null: false
    t.string "unavailability_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "building_id, LOWER(name)", name: "index_spaces_on_building_id_and_lower_name", unique: true
    t.index "campus_id, LOWER(name)", name: "index_spaces_on_campus_id_and_lower_name_without_building", unique: true, where: "building_id IS NULL"
    t.index ["campus_id"], name: "index_spaces_on_campus_id"
    t.index ["department_id"], name: "index_spaces_on_department_id"
    t.index ["usage_term_id"], name: "index_spaces_on_usage_term_id"
    t.check_constraint "(status = 'unavailable') = (unavailability_reason IS NOT NULL)", name: "spaces_unavailability_reason_matches_status"
    t.check_constraint "status IN ('available', 'unavailable', 'deactivated')", name: "spaces_status_known"
  end

  create_table "usage_terms", force: :cascade do |t|
    t.string "title", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "LOWER(title)", name: "index_usage_terms_on_lower_title", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false, null: false
    t.integer "department_id"
    t.index ["department_id"], name: "index_users_on_department_id"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "buildings", "campi"
  add_foreign_key "sessions", "users"
  add_foreign_key "spaces", "buildings"
  add_foreign_key "spaces", "campi"
  add_foreign_key "spaces", "departments"
  add_foreign_key "spaces", "usage_terms"
  add_foreign_key "users", "departments"
end
