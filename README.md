## Pumpfun Rug Watch Dashboard

### Overview
This repository contains the Dune Analytics queries for the Pumpfun Rug Watch Dashboard, developed for the MCSI Hackathon. The dashboard allows users to input a specific Pumpfun token address to analyze its lifecycle, including deployer actions, sniper wallets, early sellers, and transaction flows. It flags potential rug pulls and manipulative behaviors, making it a valuable tool for traders, security teams, and on-chain investigators in the Solana memecoin ecosystem.

### Usage

Access the dashboard on Dune Analytics (link to be provided).
Input a Pumpfun token address in the parameter field ({{token_address}}).
Explore the tables to analyze deployer activity, snipers, early sellers, and transaction patterns.

#### Queries

**Query 1: Token Information and Deployer PnL**

Description: Retrieves token metadata, launch time, graduation status, and deployer’s PnL for the specified token.

Logic Explanation:

All Launches: Identifies the token’s launch time and deployer from mint transactions.
Graduations: Checks graduation status using a pre-existing Dune query for Pumpfun tokens.
Token Meta: Fetches the token’s name and symbol.
Deployer PnL: Calculates the deployer’s profit/loss by aggregating their trades.
Output: Combines metadata, graduation details (including time to graduate), and PnL.

**Query 2: Deployer Daily Stats**

Description: Tracks the deployer’s launch and graduation history over time for the specified token’s deployer.

Logic Explanation:

Deployer Info: Identifies the deployer of the token.
All Launches: Lists all tokens launched by this deployer.
Graduations: Lists graduation dates for these tokens.
Launches/Graduations Per Day: Counts daily launches and graduations.
All Dates: Generates a date range from the first launch to today.
Output: Shows daily launches, graduations, cumulative totals, and success rate.

**Query 3: Token Deployer Buys**

Description: Lists the deployer’s buy transactions for the token, including the percentage of supply purchased.

Logic Explanation:

Deployer Info: Gets the deployer, launch time, and total supply.
Deployer Self-Buys: Finds the deployer’s buy transactions.
Trade Info: Retrieves USD values for these buys.
Output: Details buy time, amount, supply percentage, USD value, and transaction ID.

**Query 4: Token Deployer’s Token Transfers**

Description: Shows transfers from the deployer to other wallets, including supply percentage and subsequent sales by recipients.

Logic Explanation:

Deployer Info: Gets the deployer and total supply.
Deployer Transfer: Lists transfers from the deployer to other wallets.
Sales by Recipients: Aggregates sales by transfer recipients.
Output: Shows transfer time, recipient, amount, supply percentage, recipient sales, and transaction ID.

**Query 5: Token Snipers**

Description: Identifies non-deployer wallets that bought the token within 40 seconds of launch.

Logic Explanation:

Deployer Info: Gets the deployer, launch time, and total supply.
Snipes: Finds early buy transactions (1-40 seconds post-launch) by non-deployers.
Output: Lists sniper wallet, buy time, amount, supply percentage, USD value, and transaction ID.

**Query 6: Early Sellers & Wallet Tags**

Description: Tags wallets based on selling behavior and calculates their PnL.

Logic Explanation:

Deployer Info: Gets the deployer and launch time.
Early Sells: Identifies wallets that sold, with first sell time and total sold.
First Buys/Buy Counts: Tracks first buy times and buy counts per wallet.
All Buys/Sells: Aggregates buy and sell amounts.
Buy/Sell USD Values: Calculates USD spent and earned.
Output: Shows wallet, buy/sell times, amounts, buy count, tags (Deployer, Manipulator, Sniper, Early Seller, Regular Seller), and estimated profit.

### Notes

Queries use Dune Analytics datasets like tokens_solana.transfers, pumpdotfun_solana.pump_call_buy, and dex_solana.trades.
Query 1 relies on a pre-existing Dune query (query_4916985) for graduation data; replace with custom logic if unavailable.
The dashboard supports any valid Pumpfun token address via parameter input.
For detailed query implementation, refer to the source files in this repository.

### Contributing

Contributions are welcome! Please submit issues or pull requests for improvements or bug fixes.

