class UsageTerm < ApplicationRecord
  has_rich_text :content

  normalizes :title, with: ->(title) { title.squish }

  validates :title, presence: true, uniqueness: { case_sensitive: false }
  validates :content, presence: true

  scope :ordered_by_title, -> { order(:title) }
end
