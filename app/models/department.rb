class Department < ApplicationRecord
  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true, normalized_uniqueness: true

  # Sorts in Ruby because SQLite compares bytes, which puts "Coordenadoria" before "Coordenação".
  def self.sorted
    all.sort_by { |department| department.name.unicode_normalize(:nfkd).gsub(/\p{Mn}/, "").downcase(:fold) }
  end
end
