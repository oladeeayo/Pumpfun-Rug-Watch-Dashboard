WITH all_launches AS (
  SELECT
    t.token_mint_address AS token_address,
    MIN(t.block_time) AS launch_time,
    t.tx_signer AS deployer
  FROM tokens_solana.transfers t
  WHERE
    t.token_mint_address = '{{token_address}}'
    AND action = 'mint'
    AND outer_executing_account = '6EF8rrecthR5Dkzon8Nwu78hRvfCKubJ14M5uBEwF6P'
  GROUP BY t.token_mint_address, t.tx_signer
),
graduations AS (
  SELECT
    token_address,
    earliest_occurrence AS graduation_time
  FROM query_4916985
  WHERE token_address = '{{token_address}}'
),
token_meta AS (
  SELECT
    token_mint_address AS token_address,
    name,
    symbol
  FROM tokens_solana.fungible
  WHERE token_mint_address = '{{token_address}}'
),
deployer_pnl AS (
  SELECT
    trader_id AS deployer,
    '{{token_address}}' AS token_address,
    SUM(CASE WHEN token_sold_mint_address = '{{token_address}}' THEN amount_usd ELSE 0 END) -
    SUM(CASE WHEN token_bought_mint_address = '{{token_address}}' THEN amount_usd ELSE 0 END) AS pnl
  FROM dex_solana.trades
  WHERE
    '{{token_address}}' IN (token_bought_mint_address, token_sold_mint_address)
  GROUP BY trader_id
),
final AS (
  SELECT
    l.token_address,
    m.name,
    m.symbol,
    l.launch_time,
    g.graduation_time,
    CASE WHEN g.graduation_time IS NOT NULL THEN '✅' ELSE '❌' END AS graduated,
    ROUND(
      (CAST(TO_UNIXTIME(g.graduation_time) AS DOUBLE) - CAST(TO_UNIXTIME(l.launch_time) AS DOUBLE)) / 60,
      2
    ) AS minutes_to_graduate,
    ROUND(dp.pnl, 2) AS deployer_pnl
  FROM all_launches l
  LEFT JOIN graduations g ON l.token_address = g.token_address
  LEFT JOIN token_meta m ON l.token_address = m.token_address
  LEFT JOIN deployer_pnl dp ON l.deployer = dp.deployer AND l.token_address = dp.token_address
)
SELECT *
FROM final;