require "application_system_test_case"

class SidebarMenuOnPhoneTest < ApplicationSystemTestCase
  setup do
    sign_in_as create(:user)
    page.current_window.resize_to(320, 640)
    visit users_root_path
  end

  teardown do
    page.current_window.resize_to(1400, 1400)
  end

  # 44 × 44 CSS px is the target size recommended by WCAG 2.5.5 (Target Size).
  test "menu button has a 44 by 44 pixel touch target" do
    size = find_button("Menu de navegação", enable_aria_label: true).native.size

    assert_operator size.width, :>=, 44
    assert_operator size.height, :>=, 44
  end

  # The open menu's backdrop covers the button, so the second press comes from the keyboard,
  # as it does for screen reader users.
  test "menu button tells whether the menu is open" do
    assert_menu_expanded "false"

    click_on "Menu de navegação", enable_aria_label: true
    assert_menu_expanded "true"

    find_button("Menu de navegação", enable_aria_label: true).send_keys(:enter)
    assert_menu_expanded "false"
  end

  test "menu button reports the menu closed after a tap outside it" do
    click_on "Menu de navegação", enable_aria_label: true
    assert_menu_expanded "true"

    tap_outside_menu
    assert_menu_expanded "false"
  end

  test "closed menu keeps its links out of keyboard reach" do
    assert_selector "#users-sidebar[inert]", visible: :all

    click_on "Menu de navegação", enable_aria_label: true
    assert_no_selector "#users-sidebar[inert]", visible: :all

    find_button("Menu de navegação", enable_aria_label: true).send_keys(:enter)
    assert_selector "#users-sidebar[inert]", visible: :all
  end

  test "sidebar links become reachable once the screen is wide" do
    assert_selector "#users-sidebar[inert]", visible: :all

    page.current_window.resize_to(1400, 1400)

    assert_no_selector "#users-sidebar[inert]", visible: :all
  end

  test "escape closes the menu and returns focus to the menu button" do
    click_on "Menu de navegação", enable_aria_label: true
    find_link("Dashboard").send_keys(:escape)

    assert_menu_expanded "false"
    assert_selector "#users-sidebar[inert]", visible: :all
    assert_equal find_button("Menu de navegação", enable_aria_label: true), page.active_element
  end

  private

    def assert_menu_expanded(state)
      assert_selector "button[aria-label='Menu de navegação'][aria-expanded='#{state}']"
    end

    # The open menu covers the left 256 px of the screen; the backdrop covers the rest.
    def tap_outside_menu
      page.driver.browser.action.move_to_location(300, 320).click.perform
    end
end
