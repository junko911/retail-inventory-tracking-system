# Retail Inventory Tracking System

Rails app for stores, brands, products, inventory tracking events, price checks, and stockout alerts. Built on the provided starter (Rails 7.1 / Ruby 3.2 / PostgreSQL) with a 1,000,000-row tracking CSV.

## Setup

**Prerequisites:** Ruby `3.2.2`, PostgreSQL 13+, Bundler.

```bash
bundle install
bin/rails db:create db:migrate db:seed
```

Import the CSV (after seeding, and only when `tracking_events` is empty):

```bash
bin/rails tracking_events:import
```

A full import of the provided CSV produces **about 31,447 stockout alerts**. That count is a quick sanity check after import (`Alert.count` in a Rails console).

Start the server:

```bash
bin/rails server
```

Root path is the stores index. Main nav: Products, Brands, Stores, Tracking Events, Price Checks, Alerts.

Run tests:

```bash
bin/rails test
```

## What changed

### 1. Price tracking

Inventory and price are separate observations. A new `PriceCheck` model stores `price`, `product`, `store`, and `event_time` (price required, non-negative). The CSV has no price column, so price checks are seeded and created in-app only.

Price checks appear on product, store, and brand show pages (preview + "View all"), and on `/price_checks` with optional filters.

### 2. Stockout alerts

An `Alert` is created for a brand when a store has **two consecutive no-inventory** tracking events for the same product, ordered by `event_time` then `id`.

- A third stockout in the same streak does not create another alert.
- An in-stock event ends the streak; a later stockout pair can alert again.
- Each alert points at the opening and confirming events and uses the confirming event's time as `triggered_at`.

**Why the `id` tiebreak matters:** CSV dates have no time component. About **55,000** store/product/day combinations have more than one event, and about **18,000** of those disagree on inventory (`True` vs `False` on the same day). Without a deterministic second sort key, “two in a row” would be ambiguous for those ties. We order by `event_time`, then `id` (insert order).

**How alerts stay correct**

- New `TrackingEvent.create!` runs `Alerts::SyncForTrackingEvent` (after_create). Neighbor lookups use event-time order, not insert order, so out-of-order times still repair nearby streak edges.
- Bulk CSV import skips callbacks and rebuilds all alerts once with `Alerts::Backfill` (SQL window functions over store/product partitions).
- Historical data that predates alerts can also be repaired with `bin/rails alerts:backfill`.

UI: `/alerts` (paginated, optional `brand_id` filter) and a show page for the two events. Brand show previews recent alerts.

### 3. Performance

**Import**

- Load store address → id and product name → id maps once.
- Memoize `Date.parse` (the CSV repeats a small set of calendar dates) and skip rows with blank/invalid dates, missing store, or missing product.
- `insert_all` in batches of 5,000 (no per-row validations/callbacks), then one `Alerts::Backfill`, all inside a **single DB transaction**. A mid-import failure rolls back so the guard still allows a retry.
- Abort if any tracking events already exist (not idempotent; a successful second run would duplicate rows and invent false streaks).
- The importer does **not** dedupe CSV rows. See Assumptions for how duplicate / same-day rows affect alerts.

**Reads**

- Index pages use grouped `COUNT` hashes instead of `association.size` per row (N+1 against 1M events).
- Show pages preview the latest 20 tracking events, price checks, and alerts, with "View all" links to paginated indexes (50 per page) filtered by product, store, or brand.
- Tracking event indexes: `(product_id, event_time, id)`, `(store_id, event_time, id)`, and `(store_id, product_id, event_time, id)` for show/list ordering and alert neighbor lookups. The redundant single-column `product_id` index was dropped after the composite was added.

**Rough scale (why this matters)**

- The original importer did about **3 million** SQL round-trips for 1M rows (`Store.find_by` + `Product.find_by` + `TrackingEvent.create!` each row), and would be far worse once per-row alert sync is enabled.
- The bulk path is a handful of lookup queries, ~200 batched inserts, then one SQL backfill.
- A store show with ~10k events loads a count + a 20-row preview with includes (on the order of **~8 queries**), not 10k association loads.

## Key decisions

| Decision | Why |
|---|---|
| Separate `PriceCheck` table (not columns on `TrackingEvent`) | Spec says inventory and price can occur independently. Keeps the million-row inventory timeline clean. |
| Alert = start of a two-stockout streak | Matches "two no-inventory in a row"; avoids one alert per overlapping pair in a long outage. |
| Order by `event_time`, then `id` | Day-only CSV timestamps create tens of thousands of ties; `id` makes “consecutive” deterministic. |
| Sync on create + SQL backfill for import | Interactive path stays correct per event; bulk path cannot afford per-row sync. Same streak rules in both. |
| Preview + View all (not infinite show pages) | Detail pages stay light; full lists live on dedicated paginated indexes. |
| Unique brand name, store address, product name | Importer lookup hashes assume uniqueness. Product names are **globally** unique because the CSV has no brand column. |
| Import refuses a second run | Safer than silent duplication. Clear the table (and alerts) or use a fresh DB to re-import. |
| No CSV dedupe on import | Keeps import simple and preserves every row the file contains. Alert quirks from duplicates are documented below instead of inventing a collapse rule. |

## Assumptions

- One currency for prices (`decimal(10, 2)`).
- Consecutive means next event for the same store + product by `event_time`, then `id`.
- Null `event_time` events do not participate in alert detection (`tracking_events.event_time` remains nullable).
- AI assistance was used on this project (allowed by the brief).

### CSV duplicates and same-day ordering

The provided `tracking_events.csv` contains many exact duplicate rows (same address, product name, date, and inventory flag), including repeated `False` rows for the same store/product/day. Dates are day-granularity only, so ties are common (see the `id` tiebreak note above).

This project treats each imported row as its own tracking event. When two events share a store, product, and `event_time`, order is by `id` (insert order). That means:

- Two identical no-inventory rows on the same day are consecutive by `id` and **will create a stockout alert**.
- A day that has both `True` and `False` rows is ordered by insert/`id`, not by a “one observation per day” rule.

That is intentional for this take-home: consecutive is defined on the event stream as stored, not on a deduped calendar day. A production system would likely unique on `(store, product, event_time)` or collapse same-day observations before alerting.

## Known limitations

- **Alert sync is create-only.** Updating or deleting a tracking event does not resync alerts; only `after_create` does. Re-run `bin/rails alerts:backfill` to repair.
- **`alerts:backfill` rebuilds every alert** (`delete_all` + reinsert), so alert IDs change on each backfill.
- **Pagination uses `OFFSET`.** Fine for this UI; deep pages on `/tracking_events` with 1M rows will get slower.
- **Index pages recount the full event table** (`GROUP BY` counts) on every load. Rails counter caches do not update under `insert_all`, so caching or materialized counts would be the next step for those pages.
- **Importer does not dedupe** the provided CSV (see above).
- **`inventory_present` / `event_time` are still nullable** in the schema. The importer never writes nulls; null `event_time` is ignored for alerts. `NOT NULL` would be a reasonable follow-up.

## Original objectives (brief)

1. **Price tracking** - track price separately from inventory presence.
2. **Alert system** - alert the brand on two consecutive no-inventory events for a store/product.
3. **Performance** - improve overall performance alongside or after the above.

## Stack

- Ruby 3.2.2
- Rails 7.1.6
- PostgreSQL 13+
