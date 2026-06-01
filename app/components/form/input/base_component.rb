# frozen_string_literal: true

class Form::Input::BaseComponent < ViewComponent::Base
  def initialize(form:, attribute:, type:, **options)
    @object = form.object
    @form = form
    @attribute = attribute
    @type = type
    @options = options
  end

  def id
    return @attribute unless @object.present?

    class_name = @object.class.name.underscore.downcase
    "#{class_name}_#{@attribute}"
  end

  def input
    classes = "text-xs md:text-base mt-1 block w-full rounded-md border border-gray-300 py-2 px-3 shadow-sm"
    classes += " focus:border-blue-500 focus:outline-none focus:ring-blue-500"
    classes += " #{error_input_class}"

    # Extract and remove :class from options safely
    custom_class = @options.delete(:class)
    classes += " #{custom_class}" if custom_class.present?

    @form.send(input_type, @attribute, class: classes, id: id, **@options) + error_message
  end

  def label
    return if @options[:label] === false

    content_tag :label, class: "block text-xs md:text-sm font-medium text-gray-700", for: id do
      @object&.class&.human_attribute_name(@attribute) || I18n.t("form.fields.#{@attribute}")
    end
  end

  def hint
    content_tag :p, @options[:hint], class: "mt-1 text-xs text-gray-500" if @options[:hint].present?
  end

  private

    def input_type
      return "textarea" if @type.eql?(:textarea)

      "#{@type}_field"
    end

    # Errors
    # --------------------------------------------------------------
    def error_input_class
      "border border-red-500" if errors?
    end

    def error_message
      return unless errors?

      content_tag(:p, sanitize(@object.errors[@attribute].join("<br>")), class: "text-red-600 text-xs md:text-sm mt-1")
    end

    def errors?
      @object && @object.errors[@attribute].any?
    end
end
