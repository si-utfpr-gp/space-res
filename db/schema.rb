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

ActiveRecord::Schema[8.1].define(version: 2026_06_25_020215) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "approvals", force: :cascade do |t|
    t.integer "aprovador_id", null: false
    t.datetime "created_at", null: false
    t.datetime "data_aprovacao"
    t.text "justificativa"
    t.integer "reservation_id", null: false
    t.integer "sector_id", null: false
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["aprovador_id"], name: "index_approvals_on_aprovador_id"
    t.index ["reservation_id"], name: "index_approvals_on_reservation_id"
    t.index ["sector_id"], name: "index_approvals_on_sector_id"
  end

  create_table "reservation_dates", force: :cascade do |t|
    t.datetime "bloqueado_ate"
    t.datetime "created_at", null: false
    t.date "data"
    t.integer "reservation_id", null: false
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["reservation_id"], name: "index_reservation_dates_on_reservation_id"
  end

  create_table "reservations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "recorrencia"
    t.integer "space_id", null: false
    t.string "status"
    t.string "tipo_reserva"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["space_id"], name: "index_reservations_on_space_id"
    t.index ["user_id"], name: "index_reservations_on_user_id"
  end

  create_table "sectors", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "nome"
    t.integer "responsavel_id", null: false
    t.datetime "updated_at", null: false
    t.index ["responsavel_id"], name: "index_sectors_on_responsavel_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.string "token"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "spaces", force: :cascade do |t|
    t.integer "capacidade"
    t.datetime "created_at", null: false
    t.string "descricao"
    t.string "nome"
    t.boolean "requer_aprovacao"
    t.integer "sector_id", null: false
    t.boolean "status"
    t.string "tipo_espaco"
    t.datetime "updated_at", null: false
    t.index ["sector_id"], name: "index_spaces_on_sector_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.string "tipo_usuario"
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "approvals", "reservations"
  add_foreign_key "approvals", "sectors"
  add_foreign_key "approvals", "users", column: "aprovador_id"
  add_foreign_key "reservation_dates", "reservations"
  add_foreign_key "reservations", "spaces"
  add_foreign_key "reservations", "users"
  add_foreign_key "sectors", "users", column: "responsavel_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "spaces", "sectors"
end
