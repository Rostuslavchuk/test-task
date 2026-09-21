-- Dialect: PostgreSQL

WITH daily_revenue AS (
    SELECT 
        DATE(event_time) AS event_date,
        app_id,
        media_source,
        campaign,
        SUM(revenue_usd) AS total_revenue
    FROM clean_events
    GROUP BY DATE(event_time), app_id, media_source, campaign
)

SELECT 
    COALESCE(r.event_date, c.date) AS report_date,
    COALESCE(r.app_id, c.app_id) AS app_id,
    COALESCE(r.media_source, c.media_source) AS media_source,
    COALESCE(r.campaign, c.campaign) AS campaign,
    COALESCE(r.total_revenue, 0) AS total_revenue,
    COALESCE(c.cost_usd, 0) AS total_cost,
    c.impressions,
    c.clicks,
    CASE
      WHEN COALESCE(c.cost_usd, 0) = 0 THEN NULL
      ELSE COALESCE(r.total_revenue, 0) / c.cost_usd
    END AS roas
FROM daily_revenue as r
FULL OUTER JOIN campaign_costs c
    ON r.event_date = c.date
    AND r.app_id = c.app_id
    AND r.media_source = c.media_source
    AND r.campaign = c.campaign;
