WITH deployer_info AS (
    SELECT 
        tx_signer AS deployer,
        block_time AS launch_time,
        amount / 1e6 AS total_supply
    FROM tokens_solana.transfers
    WHERE token_mint_address = '{{token_address}}'
      AND action = 'mint'
      AND outer_executing_account = '6EF8rrecthR5Dkzon8Nwu78hRvfCKubJ14M5uBEwF6P'
    LIMIT 1
),
early_sells AS (
    SELECT 
        pcs.account_user AS wallet,
        MIN(pcs.call_block_time) AS first_sell_time,
        SUM(pcs.amount) / 1e6 AS amount_sold,
        ARRAY_AGG(pcs.call_tx_id ORDER BY pcs.call_block_time ASC)[1] AS first_sell_tx_id
    FROM pumpdotfun_solana.pump_call_sell pcs
    WHERE pcs.account_mint = '{{token_address}}'
    GROUP BY pcs.account_user
),
first_buys AS (
    SELECT 
        pcb.account_user,
        MIN(pcb.call_block_time) AS first_buy_time
    FROM pumpdotfun_solana.pump_call_buy pcb
    WHERE pcb.account_mint = '{{token_address}}'
    GROUP BY pcb.account_user
),
buy_counts AS (
    SELECT 
        pcb.account_user,
        COUNT(*) AS num_buys
    FROM pumpdotfun_solana.pump_call_buy pcb
    WHERE pcb.account_mint = '{{token_address}}'
    GROUP BY pcb.account_user
),
all_buys AS (
    SELECT 
        pcb.account_user,
        pcb.call_tx_id
    FROM pumpdotfun_solana.pump_call_buy pcb
    WHERE pcb.account_mint = '{{token_address}}'
),
all_sells AS (
    SELECT 
        pcs.account_user,
        pcs.call_tx_id
    FROM pumpdotfun_solana.pump_call_sell pcs
    WHERE pcs.account_mint = '{{token_address}}'
),
buy_usd_values AS (
    SELECT
        ab.account_user,
        SUM(dt.amount_usd) AS total_buy_usd
    FROM all_buys ab
    LEFT JOIN dex_solana.trades dt ON ab.call_tx_id = dt.tx_id
    GROUP BY ab.account_user
),
sell_usd_values AS (
    SELECT
        als.account_user,
        SUM(dt.amount_usd) AS total_sell_usd
    FROM all_sells als
    LEFT JOIN dex_solana.trades dt ON als.call_tx_id = dt.tx_id
    GROUP BY als.account_user
)
SELECT 
    es.wallet,
    es.first_sell_time,
    es.amount_sold,
    ROUND((es.amount_sold / di.total_supply), 4) AS percent_of_supply_sold,
    buv.total_buy_usd,
    suv.total_sell_usd,
    COALESCE(suv.total_sell_usd, 0) - COALESCE(buv.total_buy_usd, 0) AS estimated_profit_usd,
    CASE 
        WHEN es.wallet = di.deployer THEN '🛠️ Deployer'
        WHEN es.wallet != di.deployer AND fb.first_buy_time <= di.launch_time + INTERVAL '40' second THEN '⚡ Sniper'
        WHEN bc.num_buys >= 15 THEN '🚨 Mega Manipulator'
        WHEN bc.num_buys >= 6 THEN '🎭 Manipulator'
        ELSE '🧑 Normal Trader'
    END AS trader_tag,
    CASE 
        WHEN es.first_sell_time <= di.launch_time + INTERVAL '5' minute AND (es.amount_sold / di.total_supply) > 1 THEN '🚨 Ultra-Early Seller'
        WHEN es.first_sell_time <= di.launch_time + INTERVAL '15' minute AND (es.amount_sold / di.total_supply) > 1 THEN '⚠️ Early Seller'
        WHEN es.first_sell_time <= di.launch_time + INTERVAL '30' minute AND (es.amount_sold / di.total_supply) > 1 THEN '🟡 Mid-Early Seller'
        ELSE 'Normal Seller'
    END AS selloff_tag,
    es.first_sell_tx_id
FROM early_sells es
JOIN deployer_info di ON TRUE
LEFT JOIN first_buys fb ON fb.account_user = es.wallet
LEFT JOIN buy_counts bc ON bc.account_user = es.wallet
LEFT JOIN buy_usd_values buv ON buv.account_user = es.wallet
LEFT JOIN sell_usd_values suv ON suv.account_user = es.wallet
ORDER BY es.amount_sold DESC;