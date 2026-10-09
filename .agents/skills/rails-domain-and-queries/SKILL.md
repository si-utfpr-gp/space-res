---
name: rails-domain-and-queries
description: >-
  Architectural patterns for Rails domain objects, database Query Objects, eager loading contracts, expressive model helpers, and strict business invariants. Use whenever designing domain logic, creating Query Objects under app/queries/, adding model associations or predicates, or enforcing authorization and business rules.
---

# Rails Domain Objects & Query Standards

Use this skill to keep business logic explicit, testable, and independent from controllers, views, and incidental persistence details.

---

## 1. Domain Objects

Domain Objects are the umbrella category for business concepts and rules that should not be forced into controllers, views, or oversized Active Record models. Choose the specialized pattern that matches the responsibility:

| Pattern | Responsibility | Typical location |
| --- | --- | --- |
| Model domain behavior | Persistence-backed state, associations, scopes, and local invariants | `app/models/` |
| Service Object | One application workflow or multi-step operation | `app/services/` |
| Query Object | A named, read-only database query and its eager-loading contract | `app/queries/` |
| Policy Object | Authorization decisions for a subject and record | `app/policies/` |
| Value Object | An immutable concept compared by value, not identity | `app/value_objects/` |

### 1.1 Selection Rules

- Keep persistence-backed predicates, associations, and narrowly local invariants on the model.
- Use a Service Object to coordinate multiple models, transactions, external effects, or ordered steps.
- Use a Query Object when a read operation has meaningful filtering, joins, categorization, or preload requirements.
- Use a Policy Object for authorization; do not hide permission decisions in controllers or views.
- Use a Value Object for a small immutable concept such as a money amount, date range, or normalized identifier.
- Keep each object focused. Do not use a Service Object as a generic dumping ground or a Query Object to perform writes.

### 1.2 Strict Business Contracts

Business invariants must fail visibly when violated. Do not hide invalid state with permissive fallbacks, silent rescue clauses, dummy strings, or defensive navigation that changes the contract:

```ruby
# GOOD: unsupported state is explicit and observable
def display_label(record)
  case record.kind
  when "primary" then record.primary_label
  when "secondary" then record.secondary_label
  else
    raise ArgumentError, "Unsupported record kind: #{record.kind.inspect}"
  end
end

# BAD: invalid state is silently presented as valid
def display_label(record)
  record.primary_label || "Unknown"
rescue StandardError
  "Unknown"
end
```

---

## 2. Query Objects & Zero N+1 Queries

### 2.1 Encapsulate Complex Queries

Controllers should not contain multi-line queries or manual in-memory filtering. Encapsulate complex reads in Query Objects:

```ruby
class Reports::VisibleRecordsQuery
  def initialize(account:, filters:)
    @account = account
    @filters = filters
  end

  def call
    scope = @account.records
                     .active
                     .where(category: @filters[:category])
                     .includes(:owner, :tags)

    @filters[:search].present? ? scope.where("name ILIKE ?", "%#{@filters[:search]}%") : scope
  end
end
```

### 2.2 Strict Preload Contracts

Every Query Object must explicitly eager-load every association required by downstream presenters, partials, and ViewComponents. Treat the preload list as part of the object’s public contract and verify it with query logging or tests.

```ruby
def call
  @account.records
          .active
          .includes(
            :owner,
            :tags,
            { attachments: :blob },
            { category: :parent }
          )
end
```

### 2.3 Model-Level Association Helpers

When an association has a reusable scope or business meaning, define it on the model rather than querying from controllers or views:

```ruby
class Record < ApplicationRecord
  has_many :active_tags, -> { where(active: true) }, class_name: "Tag"

  def primary_tag
    active_tags.first
  end
end
```

---

## 3. Query Object Conventions

### 3.1 Naming and Directory Structure

Group Query Objects under `app/queries/<domain_namespace>/` and name them after the read operation:

- `Reports::VisibleRecordsQuery`
- `Accounts::OverdueItemsQuery`
- `Catalog::SearchQuery`

### 3.2 Single Execution Method

Expose one predictable public execution method, normally `call`. Keep initialization limited to the inputs required to build the query:

```ruby
class Catalog::SearchQuery
  def initialize(account:, term:)
    @account = account
    @term = term
  end

  def call
    @account.items.where("name ILIKE ?", "%#{@term}%").includes(:category)
  end
end
```

---

## 4. Pre-Completion Verification Checklist

1. [ ] Is complex read logic encapsulated in a Query Object under `app/queries/`?
2. [ ] Does the Query Object explicitly preload all associations required by its consumers?
3. [ ] Have query logs or tests verified that the consumer does not introduce N+1 queries?
4. [ ] Are invalid business states rejected instead of hidden by fallbacks?
5. [ ] Are local persistence rules expressed through model associations, scopes, or predicates?
6. [ ] Is each Service, Policy, or Value Object limited to one clear responsibility?
