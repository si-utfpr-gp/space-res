module CapybaraCustomAssertions
  def assert_flash_message(expected_text, component: :toastify)
    type = component == :toastify ? "div.#{component}" : "div##{component}"
    selector = find(type, wait: 5)

    within(selector, wait: 5) do
      assert_text expected_text, wait: 5
    end
  end

  def click_submit
    find('input[type="submit"]').click
  end
end
