# STABLECOIN MINTER APP

1. MIT licensed
2. Compiler ^0.8.18
3. Use the necessary OpenZeppelin library
4. Make separate library contract to help calculate collaterals and stablecoin

# Set Up Variables
1. Defining stablecoin information (name: Bitcoin Extended, symbol: BTCX, decimals: 18, maximum supply: 2,100,000,000)
2. List of collaterals allowed (stBTC, solvBTC, aBTC; They have exact same value; They are ERC20; must be an array)
3. Set collateral to stablecoin ratio (1:100) - constant
4. Track user's collateral balance
5. Track user's stablecoin balance

# Initialize contract with collateral tokens
1. Define constructor to contain pass collaterals

# Write lock function
1. Only listed collateral allowed (stBTC, solvBTC, aBTC)
2. User can lock "stBTC or solvBTC or aBTC"; can lock "stBTC and solvBTC" or "stBTC and aBTC" or "solvBTC and aBTC"; can lock "stBTC and solvBTC and aBTC"
3. User can lock `> 0` of allowed collateral
4. User set the lock duration (10 days minimum, a month, 3 months, 6 months, a year, 3 years)

# Write stablecoin mint function
1. Minting stablecoin require locking collateral
2. Minimum amount of total locked collateral is 0.01 (stBTC + solvBTC + aBTC)
3. Mint function is active when total locked collateral reaches minimum amount
4. If mint function is active each user can mint stablecoin based on their portion of collateral each user has locked
5. When total collateral locked is under 0.01 the mint function is still inactive

# Write redeem function
1. Redeeming collateral require stablecoin input 
2. each User chooses what collateral they want to redeem ("stBTC or solvBTC or aBTC" or "stBTC and solvBTC" or "stBTC and aBTC" or "solvBTC and aBTC" or "stBTC and solvBTC and aBTC")
3. When user hit the redeem function to unlock their collateral, it will show the lock duration countdown to withdraw

# Write withdraw function
1. Withdraw function is active when the lock countdown finished

# STABLECOIN DEPLOYMENT
1. Deployment
2. Helper config (RPC URL, API, ChainID) "Both Core TestMet and MainNet, excl. Anvill"
3. Interactions

# STABLECOIN MINTER TEST
1. Constructor test --> Deployment, Helper, and Interaction
2. Collateral management test
3. Stablecoin minting test
4. Library test
5. Edge and stress test
6. Event test
7. Security and access control test
