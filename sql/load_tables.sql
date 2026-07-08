INSTALL excel;
LOAD excel;

CREATE OR REPLACE TABLE asset_oec AS
SELECT 
    CAST(asset_id AS BIGINT) AS asset_id,
    CAST(market_id AS BIGINT) AS market_id,
    acquisition_date,
    equipment_class,
    oec
FROM read_xlsx('data/data_source_final.xlsx', sheet = 'asset_oec');

CREATE OR REPLACE TABLE rentals AS
SELECT 
    rental_date,
    CAST(rental_id AS BIGINT) as rental_id,
    CAST(asset_id AS BIGINT) as asset_id,
    CAST(market_id AS BIGINT) as market_id,
    rental_revenue
FROM read_xlsx('data/data_source_final.xlsx', sheet = 'rentals');

CREATE OR REPLACE TABLE market_mapping AS
SELECT 
    CAST(market_id AS BIGINT) AS market_id,
    market_name,
    market_open_date
FROM read_xlsx('data/data_source_final.xlsx', sheet = 'market_mapping');