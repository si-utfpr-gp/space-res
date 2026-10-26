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
    @form.field_id(@attribute)
  end

  def input
    input_options = @options.except(:hint, :label, :label_class, :wrapper_class)

    # Extract and remove :class from options safely
    custom_class = input_options.delete(:class)

    @form.send(input_type, @attribute, class: input_classes(custom_class), id: id, **input_options) + error_message
  end

  def label
    return if @options[:label] === false

    content_tag :label, class: label_class, for: id do
      label_text
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

    def input_classes(custom_class)
      classes = "mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 text-base shadow-sm"
      classes += " focus:border-blue-500 focus:outline-none focus:ring-blue-500"
      classes += " #{error_input_class}"
      classes += " #{custom_class}" if custom_class.present?
      classes
    end

    def label_text
      return @options[:label] if @options[:label].is_a?(String)

      @object&.class&.human_attribute_name(@attribute) || I18n.t("form.fields.#{@attribute}")
    end

    def label_class
      classes = "block text-sm font-medium text-gray-700"
      custom_class = @options[:label_class]
      classes += " #{custom_class}" if custom_class.present?
      classes
    end

    # Errors
    # --------------------------------------------------------------
    def error_input_class
      "border border-red-500" if errors?
    end

    def error_message
      return unless errors?

      content_tag(:p, sanitize(error_messages.join("<br>")), class: "text-red-600 text-sm mt-1")
    end

    def errors?
      error_messages.any?
    end

    def error_messages
      @object ? @object.errors[@attribute] : []
    end
end
