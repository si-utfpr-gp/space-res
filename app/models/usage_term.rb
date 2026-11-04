class UsageTerm < ApplicationRecord
  normalizes :title, with: ->(title) { title.squish }
  normalizes :content, with: ->(content) { content.gsub(/\r\n?/, "\n").strip }

  validates :title, presence: true, uniqueness: { case_sensitive: false }
  validates :content, presence: true

  scope :ordered_by_title, -> { order(:title) }
end
