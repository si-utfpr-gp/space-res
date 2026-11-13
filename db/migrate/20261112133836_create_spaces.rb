class CreateSpaces < ActiveRecord::Migration[8.1]
  def change
    create_table :spaces do |t|
      t.references :campus, null: false, foreign_key: true
      # No index of its own: the unique index below starts with building_id.
      t.references :building, foreign_key: true, index: false
      t.references :department, foreign_key: true
      t.references :usage_term, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.boolean :requires_approval, null: false, default: false
      t.string :status, null: false, default: "available"
      t.string :unavailability_reason

      t.timestamps

      t.check_constraint "status IN ('available', 'unavailable', 'deactivated')", name: "spaces_status_known"
      # The reason is shown to requesters, so it exists exactly while the space is unavailable.
      t.check_constraint "(status = 'unavailable') = (unavailability_reason IS NOT NULL)",
                         name: "spaces_unavailability_reason_matches_status"
    end

    # Rows without a building never collide here (NULL is distinct); the partial index covers them.
    add_index :spaces, "building_id, LOWER(name)", unique: true,
              name: "index_spaces_on_building_id_and_lower_name"
    add_index :spaces, "campus_id, LOWER(name)", unique: true, where: "building_id IS NULL",
              name: "index_spaces_on_campus_id_and_lower_name_without_building"
  end
end
