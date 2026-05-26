with funnel_events as (

    select * from {{ ref('int_funnel_events') }}

),

aggregated as (

    select
        event_date,
        funnel_stage,
        funnel_stage_name,

        -- count distinct sessions that reached each funnel stage
        count(distinct session_key) as sessions_reached

    from funnel_events
    group by event_date, funnel_stage, funnel_stage_name

),

with_drop_off as (

    select
        event_date,
        funnel_stage,
        funnel_stage_name,
        sessions_reached,

        -- how many sessions reached the previous stage
        lag(sessions_reached) over (
            partition by event_date
            order by funnel_stage
        ) as sessions_at_previous_stage,

        -- what percentage of the previous stage made it to this stage
        round(safe_divide(
            sessions_reached,
            lag(sessions_reached) over (
                partition by event_date
                order by funnel_stage
            )
        ), 4) as step_conversion_rate

    from aggregated

)

select * from with_drop_off