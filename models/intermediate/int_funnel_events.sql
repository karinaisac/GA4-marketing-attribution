with events as (

    select * from {{ ref('stg_ga4_events') }}

),

funnel_events as (

    select
        user_pseudo_id,
        session_id,
        concat(user_pseudo_id, '_', cast(session_id as string)) as session_key,
        event_date,
        event_timestamp,
        event_name,

        -- assign each funnel event a stage number so we can measure drop-off
        case event_name
            when 'view_item'        then 1
            when 'add_to_cart'      then 2
            when 'begin_checkout'   then 3
            when 'add_shipping_info' then 4
            when 'add_payment_info' then 5
            when 'purchase'         then 6
        end as funnel_stage,

        case event_name
            when 'view_item'        then 'View Item'
            when 'add_to_cart'      then 'Add to Cart'
            when 'begin_checkout'   then 'Begin Checkout'
            when 'add_shipping_info' then 'Add Shipping Info'
            when 'add_payment_info' then 'Add Payment Info'
            when 'purchase'         then 'Purchase'
        end as funnel_stage_name

    from events
    where event_name in (
        'view_item',
        'add_to_cart',
        'begin_checkout',
        'add_shipping_info',
        'add_payment_info',
        'purchase'
    )

)

select * from funnel_events