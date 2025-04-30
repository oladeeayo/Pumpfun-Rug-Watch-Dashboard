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
snipes AS (
    SELECT 
        pcb.call_block_time,
        pcb.account_user AS wallet,
        pcb.amount / 1e6 AS amount_bought,
        (pcb.amount / 1e6) / di.total_supply AS percent_of_supply_bought,
        pcb.call_tx_id AS tx_id
    FROM pumpdotfun_solana.pump_call_buy pcb
    JOIN deployer_info di ON TRUE
    WHERE pcb.account_mint = '{{token_address}}'
      AND pcb.account_user != di.deployer
      AND pcb.call_block_time BETWEEN di.launch_time AND di.launch_time + INTERVAL '40' second
)
SELECT 
    s.call_block_time,
    s.wallet,
    s.amount_bought,
    dt.amount_usd AS usd_value,
    s.percent_of_supply_bought,
    s.tx_id
FROM snipes s
LEFT JOIN dex_solana.trades dt ON s.tx_id = dt.tx_id
ORDER BY s.call_block_time;