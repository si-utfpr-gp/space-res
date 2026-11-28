require "test_helper"

# The addresses from before the administrative area was organized by campus no longer exist (#99).
class Admin::LegacyRoutesTest < ActionDispatch::IntegrationTest
  setup do
    sign_in create(:user, :admin)
    @space = create(:space, :with_building)
  end

  test "responds not found for the old campi, buildings and spaces addresses" do
    [
      "/admin/campi",
      "/admin/buildings",
      "/admin/buildings/new",
      "/admin/buildings/#{@space.building_id}/edit",
      "/admin/spaces",
      "/admin/spaces/new",
      "/admin/spaces/#{@space.id}",
      "/admin/spaces/#{@space.id}/edit",
      "/admin/spaces/#{@space.id}/unavailability/new"
    ].each do |path|
      get path

      assert_response :not_found, path
    end
  end

  test "changes nothing through the old addresses" do
    patch "/admin/spaces/#{@space.id}", params: { space: { name: "Sala nova" } }
    assert_response :not_found
    delete "/admin/buildings/#{@space.building_id}"
    assert_response :not_found
    post "/admin/spaces/#{@space.id}/deactivation"
    assert_response :not_found

    assert @space.reload.available?
    assert Building.exists?(@space.building_id)
  end
end
