class EmailValidator < ActiveModel::EachValidator
  EMAIL_REGEX = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/

  def validate_each(record, attribute, value)
    unless EMAIL_REGEX.match?(value)
      record.errors.add attribute, (options[:message] || I18n.t("errors.messages.email"))
    end
  end
end
