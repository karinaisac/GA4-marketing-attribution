with sessions as (

    select * from {{ ref('int_sessions_attributed') }}

),

aggregated as (

    select
        session_date,
        source,
        medium,
        campaign,

        -- session metrics
        count(session_key) as sessions,
        count(case when session_number = 1 then session_key end) as new_user_sessions,

        -- conversion metrics
        sum(did_convert) as conversions,
        sum(purchase_count) as total_purchases,

        -- revenue metrics
        sum(revenue) as total_revenue,

        -- derived metrics
        round(safe_divide(sum(did_convert), count(session_key)), 4) as conversion_rate,
        round(safe_divide(sum(revenue), count(session_key)), 2) as revenue_per_session,
        round(safe_divide(sum(revenue), nullif(sum(did_convert), 0)), 2) as avg_order_value

    from sessions
    group by session_date, source, medium, campaign

)

select * from aggregated