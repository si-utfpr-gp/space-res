# frozen_string_literal: true

class Form::Input::SelectComponent < Form::Input::BaseComponent
  def initialize(form:, attribute:, choices:, select_options: {}, **options)
    super(form:, attribute:, type: :select, **options)
    @choices = choices
    @select_options = select_options
  end

  # Builds the tag with Rails' select helper, as FormBuilder#select does, since f.select renders this component.
  def input
    html_options = @options.except(:hint, :label, :label_class, :wrapper_class)
    custom_class = html_options.delete(:class)

    select(
      @form.object_name, @attribute, @choices, @select_options.merge(object: @object),
      class: input_classes("min-h-11 bg-white #{custom_class}".strip), id: id, **html_options
    ) + error_message
  end

  private

    def error_messages
      super + association_error_messages
    end

    # belongs_to adds its errors to the association (campus), not to the foreign key the select edits (campus_id).
    def association_error_messages
      return [] unless @object.class.respond_to?(:reflect_on_all_associations)

      association = @object.class.reflect_on_all_associations(:belongs_to)
                           .find { |reflection| reflection.foreign_key == @attribute.to_s }
      association ? @object.errors[association.name] : []
    end
end
