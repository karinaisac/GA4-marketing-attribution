with raw_events as (

    select
        event_date,
        event_timestamp,
        event_name,
        user_pseudo_id,

        -- extract session id from nested event_params
        (select value.int_value from unnest(event_params) where key = 'ga_session_id') as session_id,

        -- extract session number (1 = first ever session for this user)
        (select value.int_value from unnest(event_params) where key = 'ga_session_number') as session_number,

        -- traffic source - cast explicitly to string to avoid struct type conflicts
        cast(traffic_source.source as string) as source,
        cast(traffic_source.medium as string) as medium,
        cast(traffic_source.name as string) as campaign,

        -- ecommerce fields
        ecommerce.transaction_id as transaction_id,
        ecommerce.purchase_revenue as revenue

    from {{ source('ga4', 'events') }}
    where _table_suffix between '20210101' and '20211231'

),

cleaned as (

    select
        parse_date('%Y%m%d', event_date) as event_date,
        timestamp_micros(event_timestamp) as event_timestamp,
        event_name,
        user_pseudo_id,
        session_id,
        session_number,

        coalesce(source, '(not set)') as source,
        coalesce(medium, '(not set)') as medium,
        coalesce(campaign, '(not set)') as campaign,

        transaction_id,
        revenue

    from raw_events
    where session_id is not null

)

select * from cleaned