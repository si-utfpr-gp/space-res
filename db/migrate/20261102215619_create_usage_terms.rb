class CreateUsageTerms < ActiveRecord::Migration[8.1]
  def change
    create_table :usage_terms do |t|
      t.string :title, null: false
      t.text :content, null: false

      t.timestamps
    end
    add_index :usage_terms, "LOWER(title)", unique: true, name: "index_usage_terms_on_lower_title"
  end
end
