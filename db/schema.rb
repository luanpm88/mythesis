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

ActiveRecord::Schema.define(version: 20140325013706) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "articles", force: true do |t|
    t.text     "title"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "content_html"
    t.integer  "infobox_template_id"
  end

  create_table "attribute_sentences", force: true do |t|
    t.integer  "attribute_id"
    t.text     "value"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "attribute_values", force: true do |t|
    t.integer  "article_id"
    t.integer  "attribute_id"
    t.text     "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "raw_value"
  end

  create_table "attributes", force: true do |t|
    t.text     "name"
    t.integer  "infobox_template_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "infobox_templates", force: true do |t|
    t.text     "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
