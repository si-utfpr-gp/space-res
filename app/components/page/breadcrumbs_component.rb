# frozen_string_literal: true

class Page::BreadcrumbsComponent < ViewComponent::Base
  def initialize(items:)
    @items = items
  end

  def render?
    @items.size > 1
  end

  def ancestors
    @items[0...-1]
  end

  def current
    @items.last
  end
end
