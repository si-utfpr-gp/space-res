require "test_helper"

class Admin::CampusOverviewPresenterTest < ActiveSupport::TestCase
  test "adds up the spaces in every status" do
    assert_equal 7, presenter(space_counts: { "available" => 5, "unavailable" => 1, "deactivated" => 1 }).spaces_count
  end

  test "tells how many spaces are in each status" do
    summary = presenter(space_counts: { "deactivated" => 1, "available" => 5, "unavailable" => 1 }).spaces_summary

    assert_equal "5 disponíveis, 1 indisponível e 1 desativado.", summary
  end

  test "uses the plural for more than one space in a status" do
    summary = presenter(space_counts: { "available" => 1, "unavailable" => 2, "deactivated" => 3 }).spaces_summary

    assert_equal "1 disponível, 2 indisponíveis e 3 desativados.", summary
  end

  test "leaves out the statuses without spaces" do
    assert_equal "2 disponíveis.", presenter(space_counts: { "available" => 2 }).spaces_summary
  end

  test "tells when there are no spaces" do
    overview = presenter(space_counts: {})

    assert_equal 0, overview.spaces_count
    assert_equal "Nenhum espaço cadastrado.", overview.spaces_summary
  end

  test "lists the building names" do
    overview = presenter(building_names: [ "Bloco B", "Bloco C", "Bloco R" ])

    assert_equal 3, overview.buildings_count
    assert_equal "Bloco B, Bloco C e Bloco R.", overview.buildings_summary
  end

  test "tells when there are no buildings" do
    overview = presenter(building_names: [])

    assert_equal 0, overview.buildings_count
    assert_equal "Nenhum bloco cadastrado.", overview.buildings_summary
  end

  private

    def presenter(space_counts: {}, building_names: [])
      Admin::CampusOverviewPresenter.new(space_counts:, building_names:)
    end
end
