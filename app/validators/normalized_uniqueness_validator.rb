class NormalizedUniquenessValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    key = comparison_key(value)
    other_values = record.class.where.not(id: record.id).pluck(attribute)

    record.errors.add(attribute, :taken) if other_values.any? { |other| comparison_key(other) == key }
  end

  private

    # Compares only letters and digits, ignoring case and accents. Runs in Ruby because
    # SQLite's LOWER() and NOCASE only fold ASCII letters and keep accents.
    def comparison_key(value)
      value.unicode_normalize(:nfkd).gsub(/\p{Mn}/, "").downcase(:fold).gsub(/[^\p{Alnum}]/, "")
    end
end
