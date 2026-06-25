class CreateApprovals < ActiveRecord::Migration[8.1]
  def change
    create_table :approvals do |t|
      t.string :status
      t.datetime :data_aprovacao
      t.text :justificativa
      t.references :reservation, null: false, foreign_key: true
      t.references :sector, null: false, foreign_key: true
      t.references :aprovador, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
