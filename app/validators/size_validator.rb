class SizeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.is_a?(ActiveStorage::Attached::Many)
      validate_many(record, attribute, value)
    else
      validate_one(record, attribute, value)
    end
  end

  private

    def validate_one(record, attribute, attachment)
      if attachment.attached?
        validate_size(record, attribute, attachment)
      else
        record.errors.add(attribute, I18n.t("errors.messages.attached.blank"))
      end
    end

    def validate_many(record, attribute, attachments)
      if attachments.attached?
        attachments.each do |attachment|
          validate_size(record, attribute, attachment)
        end
      else
        record.errors.add(attribute, I18n.t("errors.messages.attached.blank"))
      end
    end

    def validate_size(record, attribute, attachment)
      maximum = options[:maximum] || 5.megabytes
      if attachment.byte_size > maximum
        record.errors.add(attribute, I18n.t("errors.messages.attached.max_size", maximum: maximum / 1.megabyte))
      end
    end
end
