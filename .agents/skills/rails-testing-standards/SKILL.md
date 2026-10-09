---
name: rails-testing-standards
description: >-
  Guidelines for writing, maintaining, and executing automated Rails tests with Minitest, FactoryBot, integration tests, Form Object tests, and Capybara system tests. Use this skill whenever creating or updating tests, fixing test failures, or validating Rails feature implementations.
---

# Rails Testing Standards

Use focused automated tests to verify observable behavior, business rules, persistence contracts, and user workflows without coupling tests to implementation details unnecessarily.

---

## 1. Test Architecture & Directory Structure

Tests live under the repository’s `test/` directory and are organized by the behavior or Rails component under test:

| Test Type | Location | Base Class | Primary Purpose |
| :--- | :--- | :--- | :--- |
| **Models** | `test/models/` | `ActiveSupport::TestCase` | Validations, associations, normalization, scopes, and model behavior. |
| **Form Objects** | `test/forms/` | `ActiveSupport::TestCase` | Form fields, validations, exposed options, and submission behavior. |
| **Helpers** | `test/helpers/` | `ActionView::TestCase` | View helper formatting and delegation behavior. |
| **Controllers** | `test/controllers/` | `ActionDispatch::IntegrationTest` | Routes, authentication, redirects, response status, HTML, and params. |
| **System Tests** | `test/system/` | `ApplicationSystemTestCase` | Browser workflows, rendered UI, and JavaScript behavior. |

Keep each test file focused on one class, endpoint, form, or cohesive workflow. Follow the existing directory namespace used by the implementation.

---

## 2. Test Design Principles

- Test public behavior and contracts rather than private implementation details.
- Name tests as observable statements: `test "redirects to the next step" do`.
- Keep setup minimal; create only records required by the scenario.
- Use one primary behavior assertion per test, with supporting assertions for the same contract.
- Cover successful, invalid, unauthorized, boundary, and not-found behavior where applicable.
- Keep unit and integration tests fast; reserve browser tests for behavior that requires a real browser.
- Do not make tests pass by weakening production validation, authorization, or error handling.

---

## 3. FactoryBot & Test Data

FactoryBot syntax is included from `test/test_helper.rb`:

```ruby
setup do
  @user = create(:user)
end
```

Use `build` when persistence is not part of the behavior under test and `create` when the database or associations are required. Prefer traits and explicit attributes over large shared setup blocks.

For authenticated integration tests, use the shared `sign_in` helper when the request flow should include the session endpoint:

```ruby
setup do
  sign_in create(:user)
end
```

For system tests, use `sign_in_as(user)` from `ApplicationSystemTestCase` when the login form itself is not the behavior being tested. Test the login form separately in its own system or integration test.

---

## 4. Model Tests

Model tests should verify validations, associations, normalization, scopes, and domain predicates. Keep each test independent and assert the contract that callers rely on:

```ruby
class User::ValidationsTest < ActiveSupport::TestCase
  test "requires an email address" do
    user = build(:user, email_address: "")

    assert_not user.valid?
    assert_includes user.errors[:email_address], "não pode ficar em branco"
  end
end
```

Use Shoulda Matchers where they improve clarity, but do not replace behavior-focused tests with matcher-only coverage when the rule has meaningful edge cases.

---

## 5. Form Object Tests

Form Objects should be tested for validation behavior, exposed form state, normalized input, and delegation to the underlying workflow:

```ruby
class Reservations::SpaceFormTest < ActiveSupport::TestCase
  test "requires a selected space" do
    form = Reservations::SpaceForm.new(space_id: "")

    assert_not form.valid?
    assert_includes form.errors[:space_id], "não pode ficar em branco"
  end

  test "exposes the selected space" do
    form = Reservations::SpaceForm.new(space_id: "2")

    assert form.valid?
    assert_equal 2, form.selected_space[:id]
  end
end
```

Cover invalid input, valid input, retained values after validation failure, and any state-clearing or progression behavior exposed by the form.

---

## 6. Helper Tests

Helper tests inherit from `ActionView::TestCase` and should cover formatting boundaries and delegation behavior:

```ruby
class ApplicationHelperTest < ActionView::TestCase
  test "formats a duration" do
    assert_equal "4 min", format_duration(240)
  end
end
```

Include nil, empty, zero, negative, and boundary values when the helper accepts them. Assert HTML only when the helper’s HTML output is its public contract.

---

## 7. Controller Integration Tests

Use `ActionDispatch::IntegrationTest` for routes and complete request behavior. Verify status, redirects, response content, authentication, authorization, and invalid input:

```ruby
class Users::ReservationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in create(:user)
  end

  test "redirects to the first incomplete step" do
    get new_users_reservation_path

    assert_redirected_to new_users_reservation_space_path
  end

  test "rejects an invalid submission" do
    patch users_reservation_step_path(:space), params: { space: { space_id: "" } }

    assert_response :unprocessable_entity
    assert_select "p", text: /não pode ficar em branco/
  end
end
```

For HTML responses, use `assert_select` for semantic structure and important attributes. Avoid asserting the entire response body. For redirects, assert the destination and any state that must be preserved.

---

## 8. System Tests

System tests inherit from `ApplicationSystemTestCase`, which configures Capybara and headless Chrome. Use them for browser-dependent behavior such as form interaction, navigation, responsive controls, and JavaScript.

Keep suites granular. Split tests by user workflow or feature responsibility instead of creating one large browser test file. Prefer stable semantic selectors, labels, roles, and visible text over CSS implementation details.

```ruby
class Sessions::LoginTest < ApplicationSystemTestCase
  test "user signs in successfully" do
    user = create(:user, password: "password")

    visit new_session_path
    fill_in "Email address", with: user.email_address
    fill_in "Password", with: "password"
    click_on "Sign in"

    assert_current_path dashboard_path
  end
end
```

Use `sign_in_as(user)` for setup in system tests that do not test the login form. Always clean up session state through the existing base test hooks.

---

## 9. Targeted Test Execution

Run the smallest relevant test scope first:

```bash
# One test file
bin/rails test test/forms/reservations/space_form_test.rb

# One test by line
bin/rails test test/forms/reservations/space_form_test.rb:12

# A focused directory
bin/rails test test/models/user

# A specific system test
bin/rails test test/system/sessions/login/user_login_test.rb
```

Avoid running the complete system suite when a focused file or directory can validate the change. Before completion, run the targeted tests and confirm `0 failures, 0 errors`.

---

## 10. Pre-Completion Verification Checklist

1. [ ] Does every new behavior have focused automated coverage?
2. [ ] Are setup records limited to the scenario’s essential data?
3. [ ] Are invalid, boundary, unauthorized, and not-found cases covered where relevant?
4. [ ] Are Form Objects tested under `test/forms/`?
5. [ ] Are controller tests using `ActionDispatch::IntegrationTest` for request behavior?
6. [ ] Are system tests reserved for browser-dependent workflows?
7. [ ] Are selectors semantic and resilient to styling changes?
8. [ ] Did the targeted test command finish with zero failures and errors?
