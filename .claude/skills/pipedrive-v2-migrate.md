# Pipedrive v2 Resource Migration

Migrate a Pipedrive resource from v1 to v2 in the pipedrive.rb gem.

**Usage:** `/pipedrive-v2-migrate <ResourceName>`
**Example:** `/pipedrive-v2-migrate deal`

The argument is the singular PascalCase class name (e.g. `Deal`, `Person`, `Pipeline`).

> **Resources NOT available in v2 (keep on v1):** Notes — stop and inform the user if they request one of these.
If no argument is given, ask the user which resource to migrate.

---

## Step 1 — Read the v1 resource

Read `lib/pipedrive/<resource_snake_case>.rb` to identify:
- Which CRUD modules are included (Create / Read / Update / Delete)
- Any custom methods beyond standard CRUD (e.g. `find_by_name` on Person/Organization)

Custom methods will need a v2 equivalent — flag them to the user rather than silently
dropping them.

## Step 2 — Create `lib/pipedrive/v2/<resource>.rb`

Mirror the pattern of [lib/pipedrive/v2/activity.rb](lib/pipedrive/v2/activity.rb).
Include exactly the same operations that the v1 class has.

```ruby
# frozen_string_literal: true

module Pipedrive
  module V2
    class Deal < ::Pipedrive::V2::Base
      include ::Pipedrive::V2::Operations::Create
      include ::Pipedrive::V2::Operations::Read
      include ::Pipedrive::V2::Operations::Update
      include ::Pipedrive::V2::Operations::Delete
    end
  end
end
```

## Step 3 — Create `spec/lib/pipedrive/v2/<resource>_spec.rb`

Mirror the pattern of [spec/lib/pipedrive/v2/activity_spec.rb](spec/lib/pipedrive/v2/activity_spec.rb).

The spec **must** cover these cases:

1. **`#entity_name`** — returns the pluralized snake_case resource name (e.g. `"notes"`)
2. **`#build_url`** — returns `/api/v2/<plural>` with no args
3. **`#build_url` with id** — returns `/api/v2/<plural>/42`
4. **`#build_url` no token** — does NOT include `api_token` as query param
5. **`#connection`** — `x-api-token` header equals the token passed to `.new`
6. **`#create`** — stubs POST to `/api/v2/<plural>`, asserts `x-api-token` header, asserts `be_success`
7. **`#find_by_id`** — stubs GET `/api/v2/<plural>/1`, asserts `x-api-token` header, asserts `be_success`
8. **`#update`** — stubs **PATCH** (not PUT) to `/api/v2/<plural>/1`, asserts `x-api-token` header, asserts `be_success`
9. **`#delete`** — stubs DELETE to `/api/v2/<plural>/1`, asserts `x-api-token` header, asserts `be_success`
10. **`#all` cursor pagination** — stubs two pages (first returns `next_cursor: 'abc'`, second returns `next_cursor: nil`), asserts all items are collected

Use `stub_request` with `headers: { 'x-api-token' => 'token' }` on every stub.
Response bodies must be valid JSON with `success: true` and `data: {}` (or `data: []` for list endpoints).

## Step 4 — Register the require in `lib/pipedrive.rb`

Find the existing `require 'pipedrive/<resource>'` line and add the v2 require immediately after:

```ruby
# Deals
require 'pipedrive/deal'
require 'pipedrive/v2/deal'  # add this line
```

## Step 5 — Update `HISTORY.md` and `lib/pipedrive/version.rb`

Bump the patch version in `lib/pipedrive/version.rb` and add an entry at the top of `HISTORY.md`:

```markdown
## [v0.X.Y](https://github.com/hostnfly/pipedrive.rb/compare/v0.X.(Y-1)...v0.X.Y) - YYYY-MM-DD

### Added
- `Pipedrive::V2::<Resource>` — <Resource> endpoint migrated to API v2
```

## Step 6 — Run the specs

```bash
bundle exec rspec spec/lib/pipedrive/v2/<resource>_spec.rb
```

Fix any failures before declaring done. Then run the full suite to check for regressions:

```bash
bundle exec rspec
```
