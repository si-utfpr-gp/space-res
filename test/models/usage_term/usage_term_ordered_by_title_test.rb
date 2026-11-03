require "test_helper"

class UsageTermOrderedByTitleTest < ActiveSupport::TestCase
  test "orders by title" do
    [ "Termo do planetário", "Termo da quadra", "Termo do laboratório de informática" ]
      .each { |title| create(:usage_term, title: title) }

    assert_equal [ "Termo da quadra", "Termo do laboratório de informática", "Termo do planetário" ],
                 UsageTerm.ordered_by_title.map(&:title)
  end
end
