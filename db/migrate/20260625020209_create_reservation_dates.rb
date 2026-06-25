class CreateReservationDates < ActiveRecord::Migration[8.1]
  def change
    create_table :reservation_dates do |t|
      t.date :data
      t.string :status
      t.datetime :bloqueado_ate
      t.references :reservation, null: false, foreign_key: true

      t.timestamps
    end
  end
end
