require "test_helper"

class Admin::CampusSummariesQueryTest < ActiveSupport::TestCase
  test "summarizes each campus in name order" do
    pato_branco = create(:campus, name: "Pato Branco")
    guarapuava = create(:campus, name: "Guarapuava")

    assert_equal [ guarapuava, pato_branco ], summaries.map(&:campus)
  end

  test "counts the spaces, buildings and unavailable spaces of each campus" do
    guarapuava = create(:campus, name: "Guarapuava")
    create_list(:building, 3, campus: guarapuava)
    create_list(:space, 2, campus: guarapuava)
    create(:space, :unavailable, campus: guarapuava)
    create(:space, :deactivated, campus: guarapuava)
    create(:space, :unavailable)

    summary = summaries.find { |item| item.campus == guarapuava }

    assert_equal 4, summary.spaces_count
    assert_equal 3, summary.buildings_count
    assert_equal 1, summary.unavailable_spaces_count
  end

  test "counts zero for a campus without registrations" do
    create(:campus, name: "Toledo")

    summary = summaries.sole

    assert_equal [ 0, 0, 0 ], [ summary.spaces_count, summary.buildings_count, summary.unavailable_spaces_count ]
  end

  test "is empty without campi" do
    assert_empty summaries
  end

  test "runs the same number of queries for any number of campi" do
    create_list(:space, 2, :with_building)
    queries_for_two = count_queries { summaries }
    create_list(:space, 3, :with_building)

    assert_equal queries_for_two, count_queries { summaries }
  end

  private

    def summaries
      Admin::CampusSummariesQuery.new.call
    end

    def count_queries(&block)
      count = 0
      counter = ->(*, payload) { count += 1 unless payload[:name] == "SCHEMA" }
      ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
      count
    end
end
