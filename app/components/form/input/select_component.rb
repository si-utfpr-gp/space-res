# frozen_string_literal: true

class Form::Input::SelectComponent < Form::Input::BaseComponent
  SELECT_OPTIONS = %i[ prompt include_blank ].freeze

  def initialize(form:, attribute:, type:, collection:, value_method: :id, text_method: :name, **options)
    super(form:, attribute:, type:, **options)
    @collection = collection
    @value_method = value_method
    @text_method = text_method
  end

  def input
    html_options = @options.except(:hint, :label, :label_class, :wrapper_class, *SELECT_OPTIONS)
    custom_class = html_options.delete(:class)

    @form.collection_select(
      @attribute, @collection, @value_method, @text_method, @options.slice(*SELECT_OPTIONS),
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
