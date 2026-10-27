require "application_system_test_case"

class NewReservationOnPhoneTest < ApplicationSystemTestCase
  setup do
    sign_in_as create(:user)
    page.current_window.resize_to(320, 640)
  end

  teardown do
    page.current_window.resize_to(1400, 1400)
  end

  # 320 CSS px is the width WCAG 1.4.10 (Reflow) requires to work without horizontal scrolling.
  test "fits every reservation step on a 320px wide screen" do
    visit new_users_reservation_path
    assert_card_fits_screen

    choose "Sala 101"
    click_on "Próximo"
    select "Reserva única", from: "Tipo de reserva"
    fill_in "Data do evento", with: Date.new(2026, 11, 3)
    find(:label, "M1").click
    assert_card_fits_screen

    click_on "Próximo"
    assert_text "Resumo da reserva"
    assert_card_fits_screen
  end

  private

    # Widths come from clientWidth, which leaves out the desktop scrollbar that phones draw over
    # the content.
    def assert_card_fits_screen
      layout = page.evaluate_script(<<~JS)
        (() => {
          const main = document.querySelector("main")
          const card = main.querySelector(":scope > header + div")
          const mainLeft = main.getBoundingClientRect().left
          const cardRect = card.getBoundingClientRect()

          return {
            left: cardRect.left - mainLeft,
            right: mainLeft + main.clientWidth - cardRect.right,
            cardOverflow: card.scrollWidth - card.clientWidth,
            pageOverflow: document.documentElement.scrollWidth - document.documentElement.clientWidth
          }
        })()
      JS

      assert_operator layout["left"], :>, 0
      assert_in_delta layout["left"], layout["right"], 0.5
      assert_equal 0, layout["cardOverflow"]
      assert_equal 0, layout["pageOverflow"]
    end
end
