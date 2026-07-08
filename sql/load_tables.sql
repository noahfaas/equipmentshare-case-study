INSTALL excel;
LOAD excel;

CREATE OR REPLACE TABLE asset_oec AS
SELECT * FROM read_xlsx('data/data_source_final.xlsx', sheet = 'asset_oec');

CREATE OR REPLACE TABLE rentals AS
SELECT * FROM read_xlsx('data/data_source_final.xlsx', sheet = 'rentals');

CREATE OR REPLACE TABLE market_mapping AS
SELECT * FROM read_xlsx('data/data_source_final.xlsx', sheet = 'market_mapping');