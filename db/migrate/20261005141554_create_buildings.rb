class CreateBuildings < ActiveRecord::Migration[8.1]
  def change
    create_table :buildings do |t|
      t.references :campus, null: false, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end
    add_index :buildings, [ :campus_id, :name ], unique: true
  end
end
