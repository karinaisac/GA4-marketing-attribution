-- This test checks that did_convert only ever contains 0 or 1.
-- Fails if any rows are found where this is not the case.

select *
from {{ ref('stg_ga4_sessions') }}
where did_convert not in (0, 1)