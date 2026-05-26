-- This test reconciles total revenue between the purchases staging model and
-- the channel performance mart. If these two numbers do not match it means
-- revenue has been gained or lost somewhere in the transformation pipeline,
-- which would indicate a serious data quality issue.

with purchases_revenue as (

    select round(sum(revenue), 2) as total_revenue
    from {{ ref('stg_ga4_purchases') }}

),

mart_revenue as (

    select round(sum(total_revenue), 2) as total_revenue
    from {{ ref('mart_channel_performance') }}

),

comparison as (

    select
        purchases_revenue.total_revenue as purchases_total,
        mart_revenue.total_revenue as mart_total,
        purchases_revenue.total_revenue - mart_revenue.total_revenue as difference

    from purchases_revenue
    cross join mart_revenue

)

-- test fails if any rows are returned, meaning there is a difference
select *
from comparison
where difference != 0