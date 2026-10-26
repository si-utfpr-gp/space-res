class TailwindFormBuilder < ActionView::Helpers::FormBuilder
  def input(attribute, type: :text, **)
    @template.render Form::Input::BaseComponent.new(
      form: self,
      attribute: attribute,
      type: type,
      **
    )
  end

  def select(attribute, choices = nil, options = {}, html_options = {})
    @template.render Form::Input::SelectComponent.new(
      form: self,
      attribute: attribute,
      choices: choices,
      select_options: options,
      **html_options
    )
  end

  def submit(value = nil, **)
    @template.render Form::Input::SubmitComponent.new(
      form: self,
      value: value,
      **
    )
  end

  def full_error(attribute)
    return unless object && object.errors[attribute].any?

    @template.content_tag(
      :p,
      object.errors.full_messages_for(attribute).join(", "),
      class: "text-xs md:text-sm text-red-600 pl-0 p-2"
    )
  end
end
