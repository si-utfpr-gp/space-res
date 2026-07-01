# frozen_string_literal: true

class Form::Input::SubmitComponent < ViewComponent::Base
  def initialize(form:, value: nil, **options)
    @form = form
    @value = value
    @options = options
  end

  def submit
    icon_options = @options.delete(:icon) || {}
    loading_text = @options.delete(:loading_text) || I18n.t("actions.loading")

    @options[:class] = class_names(
      "btn btn-md btn-primary",
      @options[:class]
    )

    @options[:data] = (@options[:data] || {}).merge(
      turbo_submits_with: @options.dig(:data, :turbo_submits_with) || loading_text
    )

    content_tag(:button, type: "submit", name: "commit", value: @value, **@options) do
      safe_join(button_content(icon_options))
    end
  end

  private

  def button_content(icon_options)
    label = content_tag(:span, @value)
    icon = build_icon(icon_options)

    icon_options.fetch(:position, :start).to_sym == :end ? [ label, icon ].compact : [ icon, label ].compact
  end

  def build_icon(icon_options)
    icon_name = icon_options[:name]
    return unless icon_name

    icon_class = icon_options.fetch(:class, "h-3.5 w-3.5")

    helpers.icon(icon_name, class: icon_class)
  end
end
