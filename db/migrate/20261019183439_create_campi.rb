class CreateCampi < ActiveRecord::Migration[8.1]
  def change
    create_table :campi do |t|
      t.string :name, null: false

      t.timestamps
    end
    add_index :campi, :name, unique: true
  end
end
