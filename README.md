1. Stablecoin minting app

# MIT licensed
# Compiler ^0.8.18
# Use the necessary OpenZeppelin library
# Make separate library contract to help calculate collaterals and stablecoin

# Set Up Variables
- Defining stablecoin information (name: Bitcoin Extended, symbol: BTCX, decimals: 18, maximum supply: 2,100,000,000)
- List of collaterals allowed (stBTC, solvBTC, aBTC; They have exact same value; They are ERC20; must be an array)
- Set collateral to stablecoin ratio (1:100) - constant
- Track user's collateral balance
- Track user's stablecoin balance

# Initialize contract with collateral tokens
- Define constructor

# Write lock function
- Only listed collateral allowed (stBTC, solvBTC, aBTC)
- User can lock "stBTC or solvBTC or aBTC"; can lock "stBTC and solvBTC" or "stBTC and aBTC" or "solvBTC and aBTC"; can lock "stBTC and solvBTC and aBTC"
- User can lock `> 0` of allowed collateral
- user set the lock duration (10 days minimum, a month, 3 months, 6 months, a year, 3 years)

# Write stablecoin mint function
- Minting stablecoin require locking collateral
- Minimum amount of total locked collateral is 0.01 (stBTC + solvBTC + aBTC)
- Mint function is active when total locked collateral reaches minimum amount
- If mint function is active each user can mint stablecoin based on their portion of collateral each user has locked
- When total collateral locked is under 0.01 the mint function is still inactive

# Write redeem function
- Redeeming collateral require stablecoin input 
- each User chooses what collateral they want to redeem ("stBTC or solvBTC or aBTC" or "stBTC and solvBTC" or "stBTC and aBTC" or "solvBTC and aBTC" or "stBTC and solvBTC and aBTC")
- When user hit the redeem function to unlock their collateral, it will show the lock duration countdown to withdraw

# Write withdraw function
- Withdraw function is active when the lock countdown finished

2. TODO: write test of each unit
