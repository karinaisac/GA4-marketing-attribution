with sessions as (

    select * from {{ ref('stg_ga4_sessions') }}

),

purchases as (

    select * from {{ ref('stg_ga4_purchases') }}

),

purchases_aggregated as (

    -- aggregate purchases to session level to maintain one row per session
    -- a session can have multiple purchases so we sum revenue and count transactions
    select
        session_key,
        count(transaction_id) as purchase_count,
        sum(revenue) as revenue

    from purchases
    group by session_key

),

joined as (

    select
        sessions.session_key,
        sessions.user_pseudo_id,
        sessions.session_id,
        sessions.session_date,
        sessions.session_start_timestamp,
        sessions.session_end_timestamp,
        sessions.session_number,
        sessions.source,
        sessions.medium,
        sessions.campaign,
        sessions.did_convert,
        sessions.unique_event_count,

        coalesce(purchases_aggregated.purchase_count, 0) as purchase_count,
        coalesce(purchases_aggregated.revenue, 0) as revenue

    from sessions
    left join purchases_aggregated on sessions.session_key = purchases_aggregated.session_key

)

select * from joined