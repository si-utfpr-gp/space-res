class CreateSpaces < ActiveRecord::Migration[8.1]
  def change
    create_table :spaces do |t|
      t.string :nome
      t.string :descricao
      t.string :tipo_espaco
      t.integer :capacidade
      t.boolean :status
      t.boolean :requer_aprovacao
      t.references :sector, null: false, foreign_key: true

      t.timestamps
    end
  end
end
