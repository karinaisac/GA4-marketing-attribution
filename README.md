# GA4 Marketing Attribution

A dbt project that transforms raw Google Analytics 4 event data from the
Google Merchandise Store into clean, tested, and documented marketing analytics
models. The project covers channel performance, funnel analysis, and cohort
analysis, as these are the core metrics used by marketing teams to evaluate
campaign effectiveness and user behavior.

---

## Data Source

The project uses the `bigquery-public-data.ga4_obfuscated_sample_ecommerce`
public dataset available in Google BigQuery. This is real (obfuscated) GA4
event data from the Google Merchandise Store covering 2021.
The dataset contains approximately 1.2 million events across 92 days of data.

GA4 data is event-based — every interaction a user has with the website
(page views, product views, add to cart, purchases) is recorded as a separate
event row. A significant part of this project involves restructuring this data 
into more meaningful tables.

---

```
models/
├── staging/        # Clean and type raw source data. One model per source entity.
├── intermediate/   # Join and reshape staging models. Not intended for direct consumption.
└── marts/          # Final analytical models. Intended for BI tools and stakeholders.
tests/              # Custom singular tests including reconciliations.
```

### Staging
- **`stg_ga4_events`** — one row per GA4 event. Extracts nested fields from
  the raw event stream, casts types, and handles null traffic source values.
- **`stg_ga4_sessions`** — one row per session. Collapses all events belonging
  to the same user session into a single row with session-level metrics.
- **`stg_ga4_purchases`** — one row per transaction. Filters to purchase events
  only and deduplicates transactions, handling a known GA4 data quality issue
  where the same purchase event can occur multiple times.

### Intermediate
- **`int_sessions_attributed`** — one row per session with aggregated
  purchase data. Handles sessions with multiple purchases by summing revenue and
  counting transactions at the session level before joining.
- **`int_funnel_events`** — one row per funnel event per session. Filters to the
  six events that make up the purchase funnel and assigns each a stage number
  and human readable label.

### Marts
- **`mart_channel_performance`** — one row per day per channel combination.
  The primary model for evaluating marketing channel effectiveness.
- **`mart_funnel`** — one row per day per funnel stage. Shows session volume
  and drop-off rates at each stage of the purchase journey.
- **`mart_cohorts`** — one row per cohort month per months since acquisition.
  Tracks the long term revenue and conversion behavior of user cohorts.

---

## Metrics Glossary

All metrics are defined once at the mart layer and are consistent across models.

| Metric | Definition | Model |
|---|---|---|
| Sessions | Count of distinct sessions | `mart_channel_performance` |
| New User Sessions | Sessions where `session_number = 1`, indicating the user's first ever visit | `mart_channel_performance` |
| Conversions | Count of sessions that resulted in at least one purchase | `mart_channel_performance` |
| Total Purchases | Count of individual purchase transactions. Can exceed conversions if a session contained multiple purchases | `mart_channel_performance` |
| Total Revenue | Sum of purchase revenue in USD | `mart_channel_performance` |
| Conversion Rate | Conversions divided by sessions | `mart_channel_performance` |
| Revenue Per Session | Total revenue divided by total sessions | `mart_channel_performance` |
| Average Order Value | Total revenue divided by conversions. Null for channels with zero conversions | `mart_channel_performance` |
| Sessions Reached | Count of distinct sessions that reached a given funnel stage | `mart_funnel` |
| Step Conversion Rate | Proportion of sessions from the previous funnel stage that reached the current stage | `mart_funnel` |
| Active Users | Count of distinct users from a cohort who had at least one session in a given month | `mart_cohorts` |

---

## Data Quality & Validation Approach

Data quality is treated as a priority throughout the project.

### Schema Tests
Every model has a `schema.yml` file documenting all columns and defining
tests. Primary keys are tested for `not_null` and `unique` on every model.
Non-nullable columns are tested for `not_null`. The `accepted_values` test
on `int_funnel_events.event_name` ensures only the six intended funnel events
ever reach the intermediate layer.

### Custom Singular Tests
Two custom tests live in the `tests/` directory:

- **`assert_did_convert_is_binary`** — confirms that `did_convert` in
  `stg_ga4__sessions` only ever contains 0 or 1, validating the case
  statement logic that derives it.
- **`assert_revenue_reconciles`** — reconciles total revenue between
  `stg_ga4_purchases` and `mart_channel_performance`. This end-to-end
  check confirms that no revenue is gained or lost across any transformation
  step in the pipeline.

### Edge Cases Handled
- **Null traffic sources** — sessions with no recorded traffic source are
  assigned `'(not set)'` rather than being dropped, ensuring they remain
  visible in channel analysis.
- **Duplicate purchase events** — GA4 can create the same purchase event
  multiple times due to page refreshes or network retries. Duplicates are
  identified and removed in `stg_ga4_purchases` using a window function,
  keeping the earliest event per transaction.
- **Malformed transaction IDs** — purchase events where GA4 recorded the
  transaction ID as `'(not set)'` are excluded from `stg_ga4_purchases`
  as they cannot be attributed to a real transaction.
- **Multiple purchases per session** — rather than assuming one purchase per
  session, `int_sessions_attributed` aggregates purchases to the session level,
  correctly handling cases where a user completed more than one transaction in
  a single visit.

### Source Freshness
The project is configured to monitor source data freshness. In a live pipeline
connected to a GA4 export, dbt would raise a warning if the source data were
more than 3 days old and an error if more than 7 days old. This project uses
a static public dataset from 2021 so the freshness check is documented here
rather than enforced, as it would always fail against historical data.

---

## Tech Stack

- **Data warehouse** — Google BigQuery
- **Transformation** — dbt Cloud
- **Source data** — Google Analytics 4 via BigQuery public datasets
