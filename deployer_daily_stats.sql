WITH deployer_info AS (
  SELECT
    tx_signer AS deployer
  FROM tokens_solana.transfers
  WHERE
    token_mint_address = '{{token_address}}'
    AND action = 'mint'
    AND outer_executing_account = '6EF8rrecthR5Dkzon8Nwu78hRvfCKubJ14M5uBEwF6P'
  LIMIT 1
),
all_launches AS (
  SELECT
    DATE(block_time) AS launch_date,
    token_mint_address AS token_address
  FROM tokens_solana.transfers
  JOIN deployer_info AS di
    ON tx_signer = di.deployer
  WHERE
    action = 'mint'
    AND outer_executing_account = '6EF8rrecthR5Dkzon8Nwu78hRvfCKubJ14M5uBEwF6P'
),
graduations AS (
  SELECT
    DATE(earliest_occurrence) AS graduation_date,
    token_address
  FROM query_4916985
),
launches_per_day AS (
  SELECT
    launch_date,
    COUNT(*) AS tokens_launched
  FROM all_launches
  GROUP BY
    launch_date
),
graduations_per_day AS (
  SELECT
    g.graduation_date,
    COUNT(*) AS tokens_graduated
  FROM graduations AS g
  JOIN all_launches AS l
    ON g.token_address = l.token_address
  GROUP BY
    g.graduation_date
),
all_dates AS (
  SELECT
    date
  FROM (
    SELECT
      MIN(launch_date) AS min_date
    FROM launches_per_day
  ) AS min_date_table
  CROSS JOIN UNNEST(
    SEQUENCE(
      min_date_table.min_date,
      CURRENT_DATE,
      INTERVAL '1' day
    )
  ) AS t(date)
),
combined AS (
  SELECT
    ad.date,
    COALESCE(lp.tokens_launched, 0) AS tokens_launched,
    COALESCE(gp.tokens_graduated, 0) AS tokens_graduated
  FROM all_dates AS ad
  LEFT JOIN launches_per_day AS lp
    ON ad.date = lp.launch_date
  LEFT JOIN graduations_per_day AS gp
    ON ad.date = gp.graduation_date
)
SELECT
  date,
  tokens_launched,
  tokens_graduated,
  SUM(tokens_launched) OVER (ORDER BY date) AS cumulative_launched,
  SUM(tokens_graduated) OVER (ORDER BY date) AS cumulative_graduated,
  CASE
    WHEN SUM(tokens_launched) OVER (ORDER BY date) > 0
    THEN ROUND(
      SUM(tokens_graduated) OVER (ORDER BY date) * 100.0000 / SUM(tokens_launched) OVER (ORDER BY date),
      4
    )
    ELSE NULL
  END AS success_rate_percentage
FROM combined
ORDER BY
  date DESC;