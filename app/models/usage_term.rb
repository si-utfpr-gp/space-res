class UsageTerm < ApplicationRecord
  normalizes :title, with: ->(title) { title.squish }
  normalizes :content, with: ->(content) { content.gsub(/\r\n?/, "\n").strip }

  validates :title, presence: true, normalized_uniqueness: true
  validates :content, presence: true

  scope :ordered_by_title, -> { order(:title) }

  # Another request can save the same title between the uniqueness validation and this INSERT
  # or UPDATE, and the unique index on title then rejects this save. Other unique violations
  # are not about the title, so they still raise.
  def save(**)
    super
  rescue ActiveRecord::RecordNotUnique => error
    raise unless title_index_violation?(error)

    errors.add(:title, :taken)
    false
  end

  private

    # SQLite names the column ("usage_terms.title"); PostgreSQL names the index.
    def title_index_violation?(error)
      error.message.match?(/\busage_terms\.title\b|\bindex_usage_terms_on_title\b/)
    end
end
