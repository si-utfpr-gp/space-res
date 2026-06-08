# frozen_string_literal: true

class Form::Input::SubmitComponent < ViewComponent::Base
  def initialize(form:, value: nil, **options)
    @form = form
    @value = value
    @options = options
  end

  def submit
    icon_name = @options.delete(:icon)
    icon_class = @options.delete(:icon_class) || "h-3.5 w-3.5"
    classes = "btn-primary inline-flex items-center justify-center gap-2 rounded-md px-4 py-2 text-xs md:text-sm font-semibold cursor-pointer"
    @options[:class] = "#{classes} #{@options[:class]}"

    content_tag(:button, type: "submit", name: "commit", value: @value, **@options) do
      safe_join([ @value, (helpers.icon(icon_name, class: icon_class) if icon_name) ].compact, " ")
    end
  end
end
