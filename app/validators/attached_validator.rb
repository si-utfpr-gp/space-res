class AttachedValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value.attached?
      record.errors.add(attribute, I18n.t("errors.messages.attached.blank"))
    end
  end
end
