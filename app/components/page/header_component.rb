# frozen_string_literal: true

class Page::HeaderComponent < ViewComponent::Base
  def initialize(title:, subtitle: nil, breadcrumbs: [])
    @title = title
    @subtitle = subtitle
    @breadcrumbs = breadcrumbs
  end

  def render?
    @title.present?
  end
end
