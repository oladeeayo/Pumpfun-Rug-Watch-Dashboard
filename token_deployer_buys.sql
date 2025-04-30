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
deployer_self_buys AS (
    SELECT 
        pcb.account_user AS deployer_wallet,
        pcb.call_block_time,
        pcb.call_tx_id as tx_id,
        pcb.amount / 1e6 AS amount_bought,
        (pcb.amount / 1e6) / di.total_supply AS percent_of_supply_bought
    FROM pumpdotfun_solana.pump_call_buy pcb
    JOIN deployer_info di ON TRUE
    WHERE pcb.account_mint = '{{token_address}}'
      AND pcb.account_user = di.deployer
),
trade_info AS (
    SELECT 
        tx_id,
        amount_usd
    FROM dex_solana.trades
    WHERE tx_id IN (SELECT tx_id FROM deployer_self_buys)
)
SELECT 
    dsb.deployer_wallet,
    dsb.call_block_time,
    dsb.amount_bought,
    ti.amount_usd,
    dsb.percent_of_supply_bought,
    dsb.tx_id
FROM deployer_self_buys dsb
LEFT JOIN trade_info ti ON dsb.tx_id = ti.tx_id
ORDER BY dsb.call_block_time;