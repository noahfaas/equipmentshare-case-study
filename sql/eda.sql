-- Checking counts
SELECT COUNT(*) AS asset_count FROM asset_oec; -- 3903 -> looks like read_xlsx dropped the extras
SELECT COUNT(*) AS rentals_count FROM rentals; -- 34624
SELECT COUNT(*) AS market_count FROM market_mapping; -- 10

-- Checking counts and comparing raw counts to distinct counts of variables that should be primary keys
-- Note that rentals has no primary key since rental_id can be repeated across months
SELECT 
    COUNT(*) AS market_count, -- 10
    COUNT(DISTINCT market_id) AS unique_market_count 
FROM market_mapping;

SELECT 
    COUNT(*) AS asset_count, -- 3903 -> looks like read_xlsx dropped the extras
    COUNT(DISTINCT asset_id) AS unique_asset_count,
    COUNT(DISTINCT equipment_class) AS unique_eq_classes -- making sure nothing besides dirt/aerial snuck in
FROM asset_oec;

-- Checking for nulls -> none across all tables
SELECT
    count(*) FILTER (WHERE asset_id IS NULL)         AS null_asset_id,
    count(*) FILTER (WHERE market_id IS NULL)        AS null_market_id,
    count(*) FILTER (WHERE acquisition_date IS NULL) AS null_acquisition_date,
    count(*) FILTER (WHERE equipment_class IS NULL)  AS null_equipment_class,
    count(*) FILTER (WHERE oec IS NULL)              AS null_oec
FROM asset_oec;

SELECT
    count(*) FILTER (WHERE rental_date IS NULL)     AS null_rental_date,
    count(*) FILTER (WHERE rental_id IS NULL)       AS null_rental_id,
    count(*) FILTER (WHERE asset_id IS NULL)        AS null_asset_id,
    count(*) FILTER (WHERE market_id IS NULL)       AS null_market_id,
    count(*) FILTER (WHERE rental_revenue IS NULL)  AS null_rental_revenue
FROM rentals;

SELECT
    count(*) FILTER (WHERE market_id IS NULL)        AS null_market_id,
    count(*) FILTER (WHERE market_name IS NULL)      AS null_market_name,
    count(*) FILTER (WHERE market_open_date IS NULL) AS null_market_open_date
FROM market_mapping;

-- Check ranges of relevant variables
SELECT 
    MIN(market_open_date) AS first_market_open,
    MAX(market_open_date) AS last_market_open -- mid 2017, so we will need to annualize revenue
FROM market_mapping;

SELECT 
    MIN(acquisition_date) AS first_acquisition_date,
    MAX(acquisition_date) AS last_acquisition_date, -- in 2017, will need to annualize revenue on asset basis
    MIN(oec) AS min_oec,
    MAX(oec) AS max_oec,
FROM asset_oec;

SELECT
    MIN(rental_date) AS first_rental_date,
    MAX(rental_date) AS last_rental_date,
    MIN(rental_revenue) AS min_revenue, -- min is 0, which i assume means no rentals for the month, which is fine
    MAX(rental_revenue) AS max_revenue
FROM rentals;

-- Counting assets by equipment class and by market since this is how end result will be grouped
SELECT equipment_class, market_id, count(*) AS count
FROM asset_oec
GROUP BY equipment_class, market_id
ORDER BY count DESC; -- more markets here than in market_mapping, many have very few of at least one class

-- Checking mappings -> all rentals should have an asset and all assets should have a market
SELECT COUNT(*) AS rentals_without_mapped_asset
FROM rentals
WHERE asset_id NOT IN (SELECT asset_id FROM asset_oec); -- all rentals map to a real asset

SELECT COUNT(*) AS assets_without_mapped_market -- 422 assets can't be mapped to one of our markets
FROM asset_oec -- I will later drop these unmapped assets assuming they are out of scope
WHERE market_id NOT IN (SELECT market_id FROM market_mapping); 

-- Further investigating unmapped asset->market records
SELECT count(*) AS orphan_assets, sum(oec) AS orphan_oec
FROM asset_oec
WHERE market_id NOT IN (SELECT market_id FROM market_mapping);

SELECT DISTINCT market_id
FROM asset_oec
WHERE market_id NOT IN (SELECT market_id FROM market_mapping); -- 14 different unmapped markets, assuming out of scope

-- Testing if an asset can be acquired before its market open date
SELECT *
FROM asset_oec a 
JOIN market_mapping m
ON a.market_id = m.market_id -- Inner join will drop unmapped assets, which is intentional
WHERE a.acquisition_date < m.market_open_date; -- the answer is yes, so I will annualize revenue on the later (max) of these two dates per asset

-- Testing if any assets were rented before being acquired or before the home market opened
SELECT count(*) AS rentals_before_open
FROM rentals r -- found 1187 rentals before open/acquisition, considering these out of scope and dropping
JOIN asset_oec a ON r.asset_id = a.asset_id
JOIN market_mapping m ON a.market_id = m.market_id
WHERE r.rental_date < m.market_open_date OR r.rental_date < a.acquisition_date;

-- Looking at current investment (oec) by market and equipment class
SELECT equipment_class, count(*) AS n_assets, sum(oec) AS total_oec
FROM asset_oec -- roughly 5x more aerial than dirt
GROUP BY equipment_class;

SELECT market_id, count(*) AS n_assets, sum(oec) AS total_oec
FROM asset_oec
WHERE market_id IN (SELECT market_id FROM market_mapping)
GROUP BY market_id
ORDER BY total_oec DESC;

-- Measuring current asset mix by market
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
)
SELECT (e.total_aerial_oec / a.total_oec) AS aerial_mix, *
FROM aerial_oec e
JOIN total_oec_by_market a 
ON e.market_id = a.market_id
ORDER BY aerial_mix DESC -- mix ranging from 0.61 to 0.96 of aerial, heavily aerial dominated