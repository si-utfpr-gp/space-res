class ContentTypeValidator < ActiveModel::EachValidator
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
        validate_content_type(record, attribute, attachment)
      else
        record.errors.add(attribute, I18n.t("errors.messages.attached.blank"))
      end
    end

    def validate_many(record, attribute, attachments)
      if attachments.attached?
        attachments.each do |attachment|
          validate_content_type(record, attribute, attachment)
        end
      else
        record.errors.add(attribute, I18n.t("errors.messages.attached.blank"))
      end
    end

    def validate_content_type(record, attribute, attachment)
      allowed_types = options[:in] || []
      unless allowed_types.include?(attachment.content_type)
        record.errors.add(attribute, I18n.t("errors.messages.attached.content_type",
                                            allowed_types: allowed_types.join(", ")))
      end
    end
end
