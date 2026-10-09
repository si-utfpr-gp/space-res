---
name: rails-frontend-standards
description: >-
  Guidelines, patterns, and strict standards for building and updating Rails web views (ERB, ViewComponents, Tailwind CSS, Stimulus, Turbo Streams, and strict I18n localization). Use this skill whenever creating, modifying, or refactoring web views, partials, ViewComponents, Form Objects, Presenters, Decorators, view helpers, Stimulus controllers, or UI text.
---

# Rails Frontend Standards & Guidelines

This guide establishes the mandatory architectural standards and conventions for the Ruby on Rails frontend (Hotwire: Turbo + Stimulus + Tailwind CSS + ViewComponents + ERB Views), ensuring visual consistency across modules and preventing common defects such as missing translation keys, unescaped HTML, or overly complex partials.

---

## 1. Internationalization (I18n) — Strict Rule

> **GOLDEN RULE:** No user-visible string may be hardcoded in ERB templates, ViewComponents, view helpers, or controllers. All messages, page titles, form labels, placeholders, and badges must be resolved via `I18n`.

### 1.1 Strict Completeness (No Default Fallbacks)
- **FORBIDDEN**: Never provide inline default string fallbacks (`default: "..."`) in `I18n.t()` calls.
- **RATIONALE**: Supplying default English or Portuguese strings masks missing keys in locale files during development and testing, allowing untranslated or inconsistent strings to escape into production. Every string must be explicitly registered in `config/locales/pt-BR/`.

```erb
<%# GOOD: Pure key lookup - fails visibly in test if translation is missing %>
<%= t("web.accounts.index.title") %>
<%= t("web.accounts.filters.status") %>

<%# BAD: Masks missing keys and causes bilingual confusion %>
<%= t("web.accounts.index.title", default: "Accounts") %>
```

### 1.2 Translation File Locations
* **Views and UI text in general:** `config/locales/pt-BR/views.pt-BR.yml`
* **Models and attributes:** `config/locales/pt-BR/models.pt-BR.yml`
* **Sessions and authentication:** `config/locales/pt-BR/sessions.pt-BR.yml`
* **Validation errors:** `config/locales/pt-BR/errors.pt-BR.yml`
* **Date and Time formats:** `config/locales/pt-BR/date_time.pt-BR.yml`

### 1.3 Key Naming Conventions
The hierarchy in `views.pt-BR.yml` must mirror the route and component structure:

```yaml
pt-BR:
  web:
      <role>:            # admin, member, operator, etc.
      <resource>:        # dashboard, accounts, reports, etc.
        <action_or_section>: # index, show, filters, tabs, card, etc.
          <element>:   # title, subtitle, breadcrumb, empty_title, etc.
```

#### Practical Example:
```yaml
pt-BR:
  web:
    accounts:
      index:
        title: Contas
        subtitle: Gerencie suas contas
        breadcrumb: Contas
        filters:
          status: Status
          all_statuses: Todos os status
          category: Categoria
          all_categories: Todas as categorias
          clear: Limpar filtros
        tabs:
          active: Ativas
          archived: Arquivadas
          pending: Pendentes
        active_tab:
          empty_title: Nenhuma conta ativa
          empty_description: Não há contas ativas no momento.
        card:
          active_badge: Ativa
          default_owner: Proprietário
          default_category: Geral
          updating: Atualizando...
          confirm_action: Confirmar ação
```

### 1.4 Pluralization and Interpolation
Use named parameters for dynamic values, timestamps, and counts:
```yaml
# config/locales/pt-BR/views.pt-BR.yml
pt-BR:
  web:
    accounts:
      card:
        updated_at: "Atualizada às %{time}"
      count:
        one: "%{count} conta"
        other: "%{count} contas"
```

```erb
<%# ERB or ViewComponent %>
<%= t("web.accounts.card.updated_at", time: updated_at.strftime("%H:%M")) %>
<%= t("web.accounts.count", count: accounts.size) %>
```

---

## 2. Presentation Object Classification

Presentation objects adapt input for the interface without owning core business invariants.

### 2.1 Form Objects (`app/forms/`)

Use a Form Object when one user interaction validates or coordinates data that does not map cleanly to one persisted model. It may expose form fields, validations, and submission behavior, but it should delegate domain changes to models or Service Objects.

- Use Form Objects for multi-model forms, search/filter forms, and non-persistent input.
- Keep authorization and business invariants outside the form.
- Keep persistence orchestration in a Service Object when multiple records or a transaction are involved.

### 2.2 ViewComponents (`app/components/`)

Use ViewComponents for reusable markup, conditional styling, and state-dependent presentation. They should receive prepared data and remain free of business state transitions.

### 2.3 Presenters (`app/presenters/`)

Use Presenters to expose view-friendly labels, formatted values, and composed display data for a resource or collection. Presenters may delegate to I18n and helpers, but must not change records or make authorization decisions.

### 2.4 Decorators (`app/decorators/`)

Use Decorators for focused presentation behavior added around an existing object without changing its domain class. Prefer a Presenter when the object needs a cohesive view-facing API; avoid stacking decorators that obscure the source of behavior.

### 2.5 Presentation Boundaries

- Form Objects coordinate input; they do not replace domain objects.
- ViewComponents render markup; they do not define business predicates.
- Presenters and Decorators format data; they do not persist or mutate records.
- Use I18n for user-visible text in every presentation object.

---

## 3. ViewComponents (`app/components/`)

Presentation logic requiring conditional styling, markup composition, or state-dependent icons must be encapsulated in typed `ViewComponent`s under `app/components/` rather than procedural helpers that concatenate HTML strings.

### 3.1 When to Extract a ViewComponent
- Visual badges with contextual colors (e.g., `Record::StatusBadgeComponent`).
- Complex visual indicators with icons, formatting, and conditional modes (e.g., `Record::DisplayModeComponent`).
- Avatars with image variants, initials fallbacks, and strict dimensions (e.g., `Avatar::Component`).
- Timers, schedule countdowns, and overdue alerts (e.g., `Record::ScheduleComponent`).
- Toast notifications and alert banners (e.g., `Flash::ToastMessageComponent`).

### 3.2 ViewComponent Example Pattern
```ruby
# app/components/record/display_mode_component.rb
module Record
  class DisplayModeComponent < ViewComponent::Base
    attr_reader :record

    def initialize(record:)
      @record = record
    end

    def render?
      record.display_mode.present?
    end

    def highlighted?
      record.highlighted?
    end

    def formatted_label
      record.label.to_s.upcase
    end
  end
end
```

### 3.3 Domain Rules Belong in Models, Not Components
Keep ViewComponents strictly focused on rendering. Do not write business state predicates inside components or helpers. Place domain queries and status rules directly in the model:

```ruby
# In Record model
def visible?
  active? && !archived?
end

def actionable?
  visible? && !locked?
end
```

---

## 4. View Architecture & Partial Decomposition

Views must remain modular, small, and highly cohesive.

### 4.1 Composition Rules
1. **Avoid Monoliths:** No partial should exceed ~80 lines. If a view grows beyond this, decompose it into conceptual subcomponents (e.g., tabs, filters, card identity, card metadata, card actions).
2. **Explicit Locals Declaration:** At the top of every partial that receives local variables, declare them using:
   ```erb
   <%# locals: (record:, presenter:) %>
   ```
3. **Card Deconstruction Pattern:**
   Large resource cards must be divided into cohesive sub-partials:
   - `_record_identity.html.erb`: Avatar, name, category, and owner.
   - `_record_metadata.html.erb`: Status, timestamps, and display mode component.
   - `_record_footer.html.erb`: Status badge, action buttons, and timestamps.
   *Benefit:* This allows Turbo Streams to refresh sub-elements (e.g., status or timestamp) without re-rendering the entire card container.

4. **Resource Directory Structure (`app/views/web/<role>/<resource>/`):**
   - `index.html.erb`: Frame orchestration and Turbo Stream subscriptions.
   - `_filters.html.erb`: Search forms and dropdown filters.
   - `_tab_counts.html.erb`: Tab navigation bar with live counters.
   - `_<name>_tab.html.erb`: Tab container (list and empty state).
   - `_<name>_card.html.erb`: Card container with `dom_id(record)`.
   - `<action>.turbo_stream.erb`: Atomic Turbo Stream response.

---

## 5. Semantic Headings & Action Hierarchy

### 5.1 Headings Hierarchy (H1, H2, H3)
- **No manual `<h1>` in views:** The layout (`application.html.erb`) already renders the `<h1>` via `<%= yield(:head_title) %>`. Never place a raw `<h1>` tag inside page bodies or partials.
- **Section Titles:** Use `<h2>` for major sections or card container headings.
- **Cards and Subsections:** Use `<h3>` or `<h4>` for individual cards, list items, and modal titles.

### 5.2 Button and Action Hierarchy
Follow the styles defined in `app/assets/tailwind/application.css`:
- **Predefined Button Classes:** Prioritize `.btn`, `.btn-primary`, `.btn-secondary`, `.btn-delete`, `.btn-edit`.
- **Primary Action (Form submit, Main CTA):** Solid, prominent theme background.
- **Secondary Action (Filter reset, Secondary options):** Neutral styling with subtle borders.
- **Destructive Action (Cancel, Delete):** Semantics defined in `.btn-delete` or theme red.

### 5.3 Nested Action Gotcha (Clickable Cards with Action Buttons)
In HTML, `<button_to>` renders a `<form>` containing a `<button>`. **Never nest `<button_to>` or `<button>` inside an `<a>` tag** (invalid HTML, breaks click bubbling):
- If a card has an inner button, the card container must be a `<div>`.
- Wrap only the title/name in `link_to`, OR use the Tailwind overlay pattern (`relative z-10` on the button).

### 5.4 Header Cleanliness & Action Bar Placement (Strict Rule)

> **CRITICAL RULE:** Never place action buttons (such as "Novo", "Histórico", "Voltar", "Selecionar todos", or CTAs) inside `<% content_for :head_actions %>`.

#### 1. The Header is Strictly for Identity:
- The layout header must contain ONLY `<% provide :head_title, ... %>` and optionally `<% provide :head_subtitle, ... %>`.
- **FORBIDDEN:** Do NOT define `<% content_for :head_actions %>` for primary or secondary page action buttons. Placing buttons in the header crowds the title on mobile, breaks layout symmetry, and causes visual inconsistency across screens.

#### 2. Action Bars Live Below the Header Divider in the View Body:
- Place all action buttons in a dedicated toolbar row immediately below the header divider (at the top of the body/form):
  - **Single Action (e.g., "Create" or "Back"):**
    - **Primary Action (New / Create):** Aligned to the right (`flex items-center justify-end`, full-width on mobile if applicable).
    - **Navigational / Back:** Aligned to the left (`flex items-center justify-start`).
  - **Dual Actions (e.g., "View history" + "Select all"):**
    - Place on the same line (`flex items-center justify-between gap-3`).
    - **Navigational / Secondary action on the left:** Neutral/outlined button with icon (`border border-gray-200 bg-white hover:bg-gray-50 text-gray-700`).
    - **Main / Primary action on the right:** Filled button in primary accent color (`bg-indigo-600 hover:bg-indigo-700 text-white min-h-[44px] min-w-[44px]`), icon-centric with accessible `title` and `aria-label`.

#### 3. No Inline Subtitle Duplication:
- When a page defines `<% provide :head_subtitle, ... %>`, the layout header already renders that subtitle text. **Never repeat the same subtitle text** inside a paragraph or span in the view body below the header divider.

---

## 6. Hotwire Patterns (Turbo + Stimulus)

### 6.1 Turbo Frames
- Isolate filterable or mutable content areas using a distinct `turbo_frame_tag`:
  ```erb
  <%= turbo_frame_tag "records_content" do %>
    <%= render "filters" %>
    ...
  <% end %>
  ```
- Specify `turbo_frame: "records_content"` on filter forms and reset/pagination links.

### 6.2 Turbo Streams & Real-Time Updates (SolidCable)
- In the primary view, subscribe to the appropriately scoped resource channel:
  ```erb
  <%= turbo_stream_from @account, :records %>
  ```
- Broadcast actions dispatched from services must use precise targets:
  - `replace`: Replaces a modified card or counter bar.
  - `remove`: Removes a card from an active queue.
  - `prepend` / `append`: Inserts a card into a target list.
- Always wrap card items in containers with an ID generated by `dom_id(record)`.

### 6.3 Flash Messages in Turbo Streams
When responding to Turbo Stream actions, always replace `"flash-messages"` using `Flash::ToastMessageComponent`:
```erb
<%= turbo_stream.replace "flash-messages" do %>
  <%= render Flash::ToastMessageComponent.new %>
<% end %>
```

### 6.4 Modal Dialogs
Use the global `<%= turbo_frame_tag :modal %>` declared in the application layout rather than rendering static hidden modals in page templates.

### 6.5 Stimulus Controllers
- **Naming Conventions:**
  - Generic UI components: `ui--<component>` (e.g., `ui--tabs`, `ui--dropdown`).
  - Domain-specific features: `<role>--<feature>` (e.g., `admin--filters`, `account--sort`).
- **Lifecycle Awareness:** Use `connect()`, `disconnect()`, and MutationObservers to handle dynamic DOM elements inserted by Turbo Streams.

---

## 7. Mobile Ergonomics & Native Form Attributes

- **Touch Targets:** Buttons, selects, and clickable controls must have a minimum touch area of 44px on mobile (`py-2.5 px-3`, `h-11`, `min-h-[44px]`).
- **Prevent iOS Auto-Zoom:** Inputs must have a font size of at least 16px (`text-base sm:text-sm`).
- **Native Keyboard Hints:**
  - Phone / CPF / Numbers: `inputmode: "numeric"` or `inputmode: "tel"`
  - Email fields: `type: :email`, `autocomplete: "email"`, `autocapitalize: "none"`
  - Text fields without auto-correct: `autocorrect: "off"`

---

## 8. Icon Standardization & Visual Language

Never paste raw inline SVG code directly in views. Always use the centralized application icon helper:
```erb
<%= icon(:check, class: "w-4 h-4") %>
<%= icon(:building_office, class: "w-5 h-5 text-gray-500") %>
```

### 8.1 Visual Style Convention (Heroicons 24 Outline)
- **Mandatory SVG Format:** All icons registered in `IconsHelper::ICONS` must follow the **Heroicons 24 outline** specification:
  - `viewBox="0 0 24 24"`
  - `fill="none"`
  - `stroke="currentColor"`
  - `stroke-width="1.5"` (or `"2"` for compact accents)
  - `stroke-linecap="round"` and `stroke-linejoin="round"`
- **Strict Prohibition of Emojis:** Never use unicode emojis or text glyphs (e.g. `→`) in views, navigation, action cards, or badges. Always use registered outline SVG icons.

### 8.2 Action Card Icon Container Pattern
To maintain visual harmony across entry points and dashboards:
- **Card Container:** `class="group relative bg-white (or bg-gray-50 hover:bg-white) p-6 rounded-2xl border border-gray-200 shadow-sm hover:shadow-md transition-all duration-200 flex items-start space-x-5"`
- **Icon Container:** `class="w-14 h-14 rounded-xl bg-<color>-50 text-<color>-600 flex items-center justify-center flex-shrink-0 group-hover:bg-<color>-600 group-hover:text-white transition-colors duration-200"`
- **Icon Size:** `w-7 h-7`
- **Navigation Arrow:** `<span class="text-gray-400 group-hover:text-<color>-500 transition-transform transform group-hover:translate-x-1 flex-shrink-0 ml-2"><%= icon(:arrow_right, class: "w-4 h-4") %></span>`

---

## 9. Breadcrumbs (Navigation Safety)

- The profile `BaseController` establishes the root breadcrumb in `default_breadcrumbs`:
  ```ruby
  def default_breadcrumbs
    add_breadcrumb I18n.t("web.dashboard.index.breadcrumb"), dashboard_path
  end
  ```
- **Strict Method Hook (`def set_breadcrumbs`):**
  - **FORBIDDEN:** Never call `add_breadcrumb` directly inside controller action methods (such as `def index` or `def show`).
  - **RATIONALE:** In a shared breadcrumbs concern, `default_breadcrumbs` is executed during `render`. Calling `add_breadcrumb` inside an action method adds the child breadcrumb *before* the root breadcrumb runs, which inverts the trail on screen.
  - **CORRECT PATTERN:** Always define the private method `def set_breadcrumbs`:
    ```ruby
    private

      def set_breadcrumbs
        add_breadcrumb I18n.t("web.records.index.breadcrumb")
      end
    ```
- **Never** add the root breadcrumb again in child controllers. Subcontrollers should only append their specific feature path via `set_breadcrumbs`.

---

## 10. Styling and Design System Standards

### 10.1 Tab Navigation Pattern (Underline Tabs)
Follow the established underline tab design:
1. **Container:** Full-width flex container with bottom border:
   `class="flex border-b border-gray-200 mb-6 w-full"`
2. **Tab Buttons:** Distribute space equally, prevent line breaks, meet 44px touch target:
   `class="flex-1 min-w-0 flex items-center justify-center gap-1.5 sm:gap-2 py-3 px-2 sm:px-4 border-b-2 -mb-px transition-colors cursor-pointer whitespace-nowrap min-h-[44px] text-xs sm:text-sm"`
   - **Active:** `border-indigo-600 text-indigo-600 font-bold` (or module primary accent).
   - **Inactive:** `border-transparent text-gray-500 font-medium hover:text-gray-700 hover:border-gray-300`.
   - **Counter Badges:** Compact pill badge (`inline-flex items-center justify-center px-1.5 sm:px-2 py-0.5 text-xs font-bold rounded-full`).
3. **Stimulus Integration:** Handled by `data-controller="ui--tabs"`.

### 10.2 Animated Attention Indicators (Red Dot Pattern)
Whenever an element requires immediate user attention (e.g., a new event or mandatory acknowledgment):
1. **Header / Inline Pulse (Ping Effect):**
   ```erb
   <span class="relative flex h-2.5 w-2.5">
     <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-red-400 opacity-75"></span>
     <span class="relative inline-flex rounded-full h-2.5 w-2.5 bg-red-600"></span>
   </span>
   ```
2. **Floating Alert Badge (Card Corner):**
   ```erb
   <div class="absolute -top-2.5 -right-2.5 flex items-center gap-1 bg-red-600 text-white text-xs font-semibold px-2.5 py-1 rounded-full shadow-md animate-pulse">
     <span class="w-2 h-2 rounded-full bg-white"></span>
     <span><%= t("web.records.card.attention_badge") %></span>
   </div>
   ```

### 10.3 Avatar Standardization & Sizing
- **Primary Avatar (Card Protagonist):** `w-12 h-12` (48px) or `w-16 h-16` (64px in overlapping clusters).
- **Secondary / Inline Avatars:** `w-8 h-8` (32px). **Never** use sizes smaller than 32px when the image conveys identity.
- **Chat Avatars:** `w-8 h-8` (32px).

---

## 11. Pre-Completion Verification Checklist

1. [ ] Are all user-visible strings placed in `config/locales/pt-BR/views.pt-BR.yml`?
2. [ ] Are `t(...)` calls strictly free of inline `default:` fallbacks?
3. [ ] Are headings semantic (no `<h1>` in page bodies, `provide :head_title` used)?
4. [ ] Are action buttons placed in the view body below the header divider (never inside `head_actions`)?
5. [ ] Is the page subtitle free of inline duplicate repetition in the view body?
6. [ ] Are breadcrumbs defined strictly in private `def set_breadcrumbs` (never directly inside controller actions)?
7. [ ] Are clickable cards free of nested `<button_to>` inside `<a>` tags?
8. [ ] Do interactive elements meet the 44px mobile touch target requirement?
9. [ ] Are icons rendered via `icon(:name)` rather than inline SVGs?
10. [ ] Are complex UI presentations extracted to ViewComponents under `app/components/`?
11. [ ] Are cards decomposed into cohesive sub-partials (~80 line limit per partial)?
12. [ ] Are Turbo Stream flash responses updating `"flash-messages"` with `Flash::ToastMessageComponent`?
13. [ ] Do elements targeted by Turbo Streams have `id="<%= dom_id(...) %>"`?
