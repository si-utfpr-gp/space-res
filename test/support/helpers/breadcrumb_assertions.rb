module BreadcrumbAssertions
  BREADCRUMBS = "nav[aria-label='Trilha de navegação']".freeze

  def assert_breadcrumbs(links, current:)
    assert_select "#{BREADCRUMBS} ol" do
      assert_select "li", count: links.size + 1
      links.each_with_index do |(name, path), index|
        assert_select "li:nth-child(#{index + 1}) a[href='#{path}']", text: name
      end
      assert_select "li:last-child[aria-current='page']", text: current
    end
  end

  def assert_no_breadcrumbs
    assert_select BREADCRUMBS, count: 0
  end
end
