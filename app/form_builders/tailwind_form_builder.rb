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

  # Rails' grouped_collection_select, styled like select; the methods are names, not procs. With
  # group_filter_key: :method in the options, each <optgroup> carries that method of its group in
  # data-filter-key, for a script that filters the groups.
  def grouped_collection_select(attribute, collection, group_method, group_label_method, option_key_method,
                                option_value_method, options = {}, html_options = {})
    filter_key = options[:group_filter_key]
    choices = collection.map do |group|
      items = group.public_send(group_method).map { |item| [ item.public_send(option_value_method), item.public_send(option_key_method) ] }
      group_attributes = filter_key ? { data: { filter_key: group.public_send(filter_key) } } : {}

      [ group.public_send(group_label_method), items, group_attributes ]
    end

    select(attribute, choices, options.except(:group_filter_key), html_options)
  end

  def checkbox(attribute, options = {}, checked_value = "1", unchecked_value = "0")
    @template.render Form::Input::CheckboxComponent.new(
      form: self,
      attribute: attribute,
      checked_value: checked_value,
      unchecked_value: unchecked_value,
      **options
    )
  end
  alias_method :check_box, :checkbox

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
