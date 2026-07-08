/*
Plan based on EDA findings:
- annualize revenue on a per asset basis based on the maximum of acquisition date and market open date
    - only if this max occurs after 2017-01-01
- drop assets that don't map to an in-scope market
- drop rentals that occurred before market open date or acquisition date
    - using the max of the two dates, since the market should be open and the asset 
    should have been acquired for the rental to truly be in-scope
    - if i don't do this and still annualize on the market/acquisition, i will overcount revenue
*/
WITH aerial_oec AS (
    SELECT 
        SUM(oec) AS total_aerial_oec,
        market_id
    FROM asset_oec
    WHERE equipment_class = 'Aerial' AND market_id IN (SELECT market_id FROM market_mapping)
    GROUP BY market_id
),
total_oec_by_market AS (
    SELECT
        SUM(oec) AS total_oec,
        market_id
    FROM asset_oec
    WHERE market_id IN (SELECT market_id FROM market_mapping)
    GROUP BY market_id
),
current_asset_mix AS (
    SELECT 
        (e.total_aerial_oec / a.total_oec) AS aerial_mix, 
        a.market_id
    FROM aerial_oec e
    JOIN total_oec_by_market a 
    ON e.market_id = a.market_id
),
asset_scope AS (
    SELECT
        a.asset_id,
        GREATEST(DATE '2017-01-01', a.acquisition_date, m.market_open_date) AS in_scope_date,
        a.market_id,
        a.oec,
        a.equipment_class
    FROM asset_oec a
    JOIN market_mapping m ON a.market_id = m.market_id
),
in_scope_annualized_rental_revenue_by_asset AS (
    SELECT
        COALESCE(SUM(r.rental_revenue), 0) AS revenue_sum, -- 0 for rev sum if not in rentals
        (365.0 / DATEDIFF('day', a.in_scope_date, '2018-01-01')) * COALESCE(SUM(r.rental_revenue), 0) AS revenue_sum_annualized,
        a.asset_id,
        a.market_id,
        a.oec,
        a.equipment_class
    FROM asset_scope a
    LEFT JOIN rentals r
    ON r.asset_id = a.asset_id
    WHERE r.rental_date >= a.in_scope_date
    GROUP BY a.asset_id, a.in_scope_date, a.market_id, a.oec, a.equipment_class
),
market_summary_dirt AS (
    SELECT 
        m.market_id, 
        m.market_name, 
        SUM(r.revenue_sum_annualized) AS dirt_ann_rev,
        SUM(r.oec) AS dirt_oec_sum,
        SUM(r.revenue_sum_annualized) / SUM(r.oec) AS dirt_fin_util
    FROM market_mapping m 
    LEFT JOIN in_scope_annualized_rental_revenue_by_asset r
    ON m.market_id = r.market_id
    WHERE r.equipment_class = 'Dirt'
    GROUP BY m.market_id, m.market_name
),
market_summary_aerial AS (
    SELECT 
        m.market_id, 
        m.market_name, 
        SUM(r.revenue_sum_annualized) AS aerial_ann_rev,
        SUM(r.oec) AS aerial_oec_sum,
        SUM(r.revenue_sum_annualized) / SUM(r.oec) AS aerial_fin_util
    FROM market_mapping m 
    LEFT JOIN in_scope_annualized_rental_revenue_by_asset r
    ON m.market_id = r.market_id
    WHERE r.equipment_class = 'Aerial'
    GROUP BY m.market_id, m.market_name
),
sample_size AS (
    SELECT
        market_id,
        LEAST(
            COUNT(*) FILTER (WHERE equipment_class = 'Aerial'),
            COUNT(*) FILTER (WHERE equipment_class = 'Dirt')
        ) AS binding_sample_size
    FROM asset_oec
    WHERE market_id IN (SELECT market_id FROM market_mapping)
    GROUP BY market_id
),
market_summary AS (
    SELECT 
        --d.market_id AS market_id,
        d.market_name AS market_name,
        --d.dirt_ann_rev AS dirt_ann_rev,
        --d.dirt_oec_sum AS dirt_oec_sum,
        ROUND(c.aerial_mix, 2) AS aerial_mix,
        ROUND(d.dirt_fin_util, 2) AS dirt_fin_util,
        ROUND(a.aerial_fin_util, 2) AS aerial_fin_util,
        ROUND(a.aerial_fin_util - d.dirt_fin_util, 2) AS aerial_fu_diff,
        s.binding_sample_size AS sample_size
    FROM current_asset_mix c
    JOIN market_summary_dirt d
    ON c.market_id = d.market_id
    JOIN market_summary_aerial a
    ON c.market_id = a.market_id
    JOIN sample_size s
    ON c.market_id = s.market_id
)
SELECT * FROM market_summary;
