class NormalizedUniquenessValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    name = ComparableName.from(value)
    scope = Array(options[:scope]).index_with { |column| record.read_attribute(column) }
    other_values = record.class.where(scope).where.not(id: record.id).pluck(attribute)

    record.errors.add(attribute, :taken) if other_values.any? { |other| ComparableName.from(other) == name }
  end
end
