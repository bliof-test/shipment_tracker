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

ActiveRecord::Schema.define(version: 20160209134817) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "builds", force: :cascade do |t|
    t.string   "version"
    t.boolean  "success"
    t.string   "source"
    t.datetime "event_created_at"
  end

  add_index "builds", ["version"], name: "index_builds_on_version", using: :btree

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "deploys", force: :cascade do |t|
    t.string   "app_name"
    t.string   "server"
    t.string   "version"
    t.string   "deployed_by"
    t.datetime "event_created_at"
    t.string   "environment"
    t.string   "region"
  end

  add_index "deploys", ["server", "app_name"], name: "index_deploys_on_server_and_app_name", using: :btree
  add_index "deploys", ["version"], name: "index_deploys_on_version", using: :btree

  create_table "event_counts", force: :cascade do |t|
    t.string  "snapshot_name"
    t.integer "event_id"
  end

  create_table "events", force: :cascade do |t|
    t.json     "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "type"
  end

  create_table "git_repository_locations", force: :cascade do |t|
    t.string   "uri"
    t.string   "name"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "remote_head"
  end

  add_index "git_repository_locations", ["name"], name: "index_git_repository_locations_on_name", unique: true, using: :btree

  create_table "manual_tests", force: :cascade do |t|
    t.string   "email"
    t.string   "versions",   array: true
    t.boolean  "accepted"
    t.text     "comment"
    t.datetime "created_at"
  end

  add_index "manual_tests", ["versions"], name: "index_manual_tests_on_versions", using: :gin

  create_table "tickets", force: :cascade do |t|
    t.string   "key"
    t.string   "summary"
    t.string   "status"
    t.text     "paths",            array: true
    t.datetime "event_created_at"
    t.string   "versions",         array: true
    t.datetime "approved_at"
  end

  add_index "tickets", ["key"], name: "index_tickets_on_key", using: :btree
  add_index "tickets", ["paths"], name: "index_tickets_on_paths", using: :gin
  add_index "tickets", ["versions"], name: "index_tickets_on_versions", using: :gin

  create_table "tokens", force: :cascade do |t|
    t.string   "source"
    t.string   "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "name"
  end

  add_index "tokens", ["value"], name: "index_tokens_on_value", unique: true, using: :btree

  create_table "uatests", force: :cascade do |t|
    t.string   "server"
    t.boolean  "success"
    t.string   "test_suite_version"
    t.datetime "event_created_at"
    t.text     "versions",           array: true
  end

  add_index "uatests", ["versions"], name: "index_uatests_on_versions", using: :gin

end
