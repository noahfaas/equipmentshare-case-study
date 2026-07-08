-- Checking counts
SELECT COUNT(*) AS asset_count FROM asset_oec; -- 3903 -> looks like read_xlsx dropped the extras
SELECT COUNT(*) AS rentals_count FROM rentals; -- 34624
SELECT COUNT(*) AS market_count FROM market_mapping; -- 10

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
