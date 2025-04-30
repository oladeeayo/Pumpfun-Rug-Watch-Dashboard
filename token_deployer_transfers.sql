WITH deployer_transfer AS (
    SELECT 
        t.block_time,
        t.to_owner,
        t.amount / 1e6 AS amount_transferred,
        t.tx_id,
        (t.amount / 1e6) / 1000000000 AS percent_of_total_supply_transferred
    FROM tokens_solana.transfers t
    WHERE t.token_mint_address = '{{token_address}}'
      AND t.action = 'transfer'
      AND t.outer_instruction_index = 2
      AND t.inner_instruction_index = 0
      AND t.from_owner = (
            SELECT DISTINCT tx_signer
            FROM tokens_solana.transfers
            WHERE token_mint_address = '{{token_address}}'
              AND action = 'mint'
              AND outer_executing_account = '6EF8rrecthR5Dkzon8Nwu78hRvfCKubJ14M5uBEwF6P'
            LIMIT 1
      )
),
sales_by_recipients AS (
    SELECT 
        pcs.account_user AS wallet,
        SUM(pcs.amount) / 1e6 AS amount_sold,
        MIN(pcs.call_block_time) AS first_sell_time
    FROM pumpdotfun_solana.pump_call_sell pcs
    WHERE pcs.account_mint = '{{token_address}}'
    GROUP BY pcs.account_user
)
SELECT
    dt.block_time AS transfer_block_time,
    dt.to_owner AS wallet,
    dt.amount_transferred,
    dt.tx_id,
    dt.percent_of_total_supply_transferred,
    COALESCE(sbr.amount_sold, 0) AS amount_sold,
    sbr.first_sell_time
FROM deployer_transfer dt
LEFT JOIN sales_by_recipients sbr
    ON dt.to_owner = sbr.wallet
ORDER BY dt.block_time;