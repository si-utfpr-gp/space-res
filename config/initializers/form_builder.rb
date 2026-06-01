module DefaultNovalidateForFormWith
  def form_with(**options, &)
    options[:html] ||= {}
    options[:html][:novalidate] = true unless options[:html].key?(:novalidate)
    super
  end
end

Rails.application.config.to_prepare do
  ActionView::Base.default_form_builder = TailwindFormBuilder
  ActionView::Helpers::FormHelper.prepend(DefaultNovalidateForFormWith)
end
