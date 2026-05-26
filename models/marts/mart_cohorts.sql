with sessions as (

    select * from {{ ref('int_sessions_attributed') }}

),

-- find the first session date for each user
user_cohorts as (

    select
        user_pseudo_id,
        date_trunc(min(session_date), month) as cohort_month

    from sessions
    group by user_pseudo_id

),

-- join cohort month back to all sessions
sessions_with_cohort as (

    select
        sessions.session_key,
        sessions.user_pseudo_id,
        sessions.session_date,
        sessions.revenue,
        sessions.did_convert,
        user_cohorts.cohort_month,

        -- how many months after acquisition did this session occur
        date_diff(
            date_trunc(sessions.session_date, month),
            user_cohorts.cohort_month,
            month
        ) as months_since_acquisition

    from sessions
    left join user_cohorts on sessions.user_pseudo_id = user_cohorts.user_pseudo_id

),

aggregated as (

    select
        cohort_month,
        months_since_acquisition,

        -- how many users from this cohort were active in this month
        count(distinct user_pseudo_id) as active_users,

        -- how much revenue did this cohort generate in this month
        sum(revenue) as revenue,

        -- how many conversions did this cohort generate in this month
        sum(did_convert) as conversions

    from sessions_with_cohort
    group by cohort_month, months_since_acquisition

)

select * from aggregated