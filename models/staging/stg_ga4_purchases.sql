with raw_events as (

    select * from {{ ref('stg_ga4_events') }}

),

purchase_events as (

    select
        user_pseudo_id,
        session_id,
        concat(user_pseudo_id, '_', cast(session_id as string)) as session_key,
        event_date as purchase_date,
        event_timestamp as purchase_timestamp,
        transaction_id,
        revenue

    from raw_events
    where event_name = 'purchase'
        and transaction_id is not null
        and transaction_id != '(not set)'

),

deduped as (

    select *
    from purchase_events
    qualify row_number() over (
        partition by transaction_id
        order by purchase_timestamp asc
    ) = 1

)

select * from deduped