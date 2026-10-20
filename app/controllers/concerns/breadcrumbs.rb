module Breadcrumbs
  extend ActiveSupport::Concern

  Breadcrumb = Data.define(:name, :path)

  included do
    helper_method :breadcrumbs
  end

  private

    # Built when the layout first asks for it, so the base trail always comes before the page's own.
    def breadcrumbs
      @breadcrumbs ||= build_breadcrumbs
    end

    def build_breadcrumbs
      @breadcrumbs = []
      default_breadcrumbs
      set_breadcrumbs
      @breadcrumbs
    end

    def add_breadcrumb(name, path = nil)
      @breadcrumbs << Breadcrumb.new(name:, path:)
    end

    def clear_breadcrumbs
      @breadcrumbs = []
    end

    def default_breadcrumbs
    end

    def set_breadcrumbs
    end
end
