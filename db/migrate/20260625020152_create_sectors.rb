class CreateSectors < ActiveRecord::Migration[8.1]
  def change
    create_table :sectors do |t|
      t.string :nome
      t.references :responsavel, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
