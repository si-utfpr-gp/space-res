class UsageTerm < ApplicationRecord
  # Before the rich text, so a refused deletion stops before the text is touched.
  has_many :spaces, dependent: :restrict_with_error
  has_rich_text :content

  normalizes :title, with: ->(title) { title.squish }

  validates :title, presence: true, uniqueness: { case_sensitive: false }
  validates :content, presence: true

  scope :ordered_by_title, -> { order(:title) }
end
