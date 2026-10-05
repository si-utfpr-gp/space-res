# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Only on an empty table: other campi come from the admin area, and a renamed
# Guarapuava campus must not be created again.
Campus.create!(name: "Guarapuava") if Campus.none?
