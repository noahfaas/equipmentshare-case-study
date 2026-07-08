-- Checking counts
SELECT COUNT(*) AS asset_count FROM asset_oec; -- 3903 -> looks like read_xlsx dropped the extras
SELECT COUNT(*) AS rentals_count FROM rentals; -- 34624
SELECT COUNT(*) AS market_count FROM market_mapping; -- 10


