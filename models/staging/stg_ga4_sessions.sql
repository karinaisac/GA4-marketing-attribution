with events as (

    select * from {{ ref('stg_ga4_events') }}

),

sessions as (

    select
        user_pseudo_id,
        session_id,

        -- a session is uniquely identified by the combination of user and session id
        -- we concatenate them into a single key to use as a primary key
        concat(user_pseudo_id, '_', cast(session_id as string)) as session_key,

        min(event_date) as session_date,
        min(event_timestamp) as session_start_timestamp,
        max(event_timestamp) as session_end_timestamp,

        -- session number is the same for all events in a session so we just take the max
        max(session_number) as session_number,

        -- traffic source is the same for all events in a session so we just take the max
        max(source) as source,
        max(medium) as medium,
        max(campaign) as campaign,

        -- a session converted if any event in it was a purchase
        max(case when event_name = 'purchase' then 1 else 0 end) as did_convert,

        -- total revenue for the session, null if no purchase occurred
        sum(revenue) as revenue,

        -- count of distinct event types as a proxy metric for engagement (higher count, more engagement)
        count(distinct event_name) as unique_event_count

    from events
    group by user_pseudo_id, session_id, session_key

)

select * from sessions