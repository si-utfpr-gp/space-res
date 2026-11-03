class CreateUsageTerms < ActiveRecord::Migration[8.1]
  def change
    create_table :usage_terms do |t|
      t.string :title, null: false
      t.text :content, null: false

      t.timestamps
    end
    add_index :usage_terms, :title, unique: true
  end
end
