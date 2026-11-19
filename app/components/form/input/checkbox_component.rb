# frozen_string_literal: true

class Form::Input::CheckboxComponent < Form::Input::BaseComponent
  def initialize(form:, attribute:, checked_value: "1", unchecked_value: "0", **options)
    super(form:, attribute:, type: :checkbox, **options)
    @checked_value = checked_value
    @unchecked_value = unchecked_value
  end

  # Builds the tag with Rails' checkbox helper, as FormBuilder#checkbox does, since f.checkbox renders this component.
  def input
    html_options = @options.except(:hint, :label, :label_class, :wrapper_class)
    custom_class = html_options.delete(:class)

    checkbox(
      @form.object_name, @attribute,
      { object: @object, class: input_classes(custom_class), id: id, **html_options },
      @checked_value, @unchecked_value
    )
  end

  private

    def input_classes(custom_class)
      class_names(
        "h-5 w-5 shrink-0 rounded border-gray-300 text-primary focus:ring-2 focus:ring-primary/40",
        error_input_class, custom_class
      )
    end

    # The label fills the row, so the whole 44px line toggles the checkbox.
    def label_class
      class_names("flex min-h-11 flex-1 cursor-pointer items-center text-sm font-medium text-gray-700", @options[:label_class])
    end
end
