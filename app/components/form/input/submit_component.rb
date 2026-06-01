# frozen_string_literal: true

class Form::Input::SubmitComponent < ViewComponent::Base
  def initialize(form:, value: nil, **options)
    @form = form
    @value = value
    @options = options
  end

  def submit
    classes = "btn-primary text-xs md:text-sm py-2 px-4 rounded-md cursor-pointer"
    @options[:class] = "#{classes} #{@options[:class]}"
    @options[:value] = @value if @value.present?

    call_parent_method(@form, :submit, **@options)
  end

  private

    # this is necessary to avoid infinite recursion in submit method
    def call_parent_method(instance, method, *)
      instance.class.superclass.instance_method(method).bind(instance).call(*)
    end
end
