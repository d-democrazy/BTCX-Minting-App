// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {CollateralManager} from "src/CollateralManager.sol";

contract StablecoinMinter {
    /**
     * errors ******
     */
    error StablecoinMinter__InsufficientAllowedCollateral();
    error StablecoinMinter__MoreThanZeroAmount();
    error StablecoinMinter__NotAllowedCollateral();
    error StablecoinMinter__InvalidLockDuration();
    error StablecoinMinter__TotalCollateralLockedMustBeAtLeastMoreThanMinimum();
    error StablecoinMinter__TotalCollateralLockedExceedsMaximum();
    error StablecoinMinter__ExceedsMaximumSupply();
    error StablecoinMinter__InsufficientStablecoinBalance();
    error StablecoinMinter__LockExpired_WithdrawDirectly();
    error StablecoinMinter__InsufficientCollateralBalance();
    error StablecoinMinter__LockStillAlive();
    error StablecoinMinter__NoCollateralToWithdraw();

    using CollateralManager for IERC20[];
    using CollateralManager for mapping(address => mapping(IERC20 => uint256));

    // Defining variables
    string public constant name = "Bitcoin Extended";
    string public constant symbol = "BTCX";
    uint256 public constant decimals = 1e18;
    uint256 public constant maximumSupply = 2_100_000_000 * decimals;

    uint256 public totalCollateralLocked;
    uint256 public immutable MINIMUM_COLLATERAL = 1e16;
    uint256 public immutable MAXIMUM_COLLATERAL = 21_000_000 * decimals;

    IERC20[] public allowedCollaterals; // Allowed collaterals (stBTC, solvBTC, aBTC)
    uint256 public constant collateralToStablecoinRatio = 100; // Collateral : stablecoin is 1 : 100

    mapping(address => mapping(IERC20 => uint256)) public userCollateralBalances;
    mapping(address => uint256) public userStablecoinBalances;

    mapping(address => mapping(IERC20 => uint256)) public lockExpiration;
    mapping(address => mapping(IERC20 => uint256)) public lockTimestamp;

    event LockCountdown(address indexed user, IERC20 indexed collateral, uint256 remainingTime, uint256 timestamp);

    constructor(IERC20[] memory _allowedCollaterals) {
        if (_allowedCollaterals.length == 0) {
            revert StablecoinMinter__InsufficientAllowedCollateral();
        }
        for (uint256 i = 0; i < _allowedCollaterals.length; i++) {
            allowedCollaterals.push(_allowedCollaterals[i]);
        }
    }

    function lockCollateral(IERC20 collateral, uint256 amount, uint256 duration) external {
        if (amount <= 0) {
            revert StablecoinMinter__MoreThanZeroAmount();
        }

        // Use library to check if the collateral is allowed
        if (!allowedCollaterals.isAllowedCollaterals(collateral)) {
            revert StablecoinMinter__NotAllowedCollateral();
        }

        // Validate duration: must be one of the allowed duration
        if (
            duration != 10 days && duration != 30 days && duration != 90 days && duration != 180 days
                && duration != 365 days && duration != 1095 days
        ) {
            revert StablecoinMinter__InvalidLockDuration();
        }

        if (totalCollateralLocked + amount > MAXIMUM_COLLATERAL) {
            revert StablecoinMinter__TotalCollateralLockedExceedsMaximum();
        }

        // Update the user's collateral balances and the total collateral locked
        userCollateralBalances[msg.sender][collateral] += amount;
        totalCollateralLocked += amount;

        // Set lock expiration and timestamp
        lockExpiration[msg.sender][collateral] = block.timestamp + duration;
        lockTimestamp[msg.sender][collateral] = block.timestamp;

        // Transfer collateral from the user to the contract
        SafeERC20.safeTransferFrom(collateral, msg.sender, address(this), amount);
    }

    function mintStablecoin() external {
        uint256 amount;
        // Ensure the total collateral locked accross all users meet the minimum treshold
        if (totalCollateralLocked < MINIMUM_COLLATERAL) {
            revert StablecoinMinter__TotalCollateralLockedMustBeAtLeastMoreThanMinimum();
        }

        if (totalCollateralLocked + amount > MAXIMUM_COLLATERAL) {
            revert StablecoinMinter__TotalCollateralLockedExceedsMaximum();
        }

        // Use library to calculate the user's collateral balance
        uint256 userTotalCollateral = userCollateralBalances.getUserTotalCollateral(allowedCollaterals, msg.sender);

        // Calculate user's mintable stablecoins based on their share of the total collateral
        uint256 mintableStablecoin =
            (userTotalCollateral * collateralToStablecoinRatio * totalCollateralLocked) / totalCollateralLocked;

        // Ensure minting doesn't exceed the maximum supply
        if (userStablecoinBalances[msg.sender] + mintableStablecoin > maximumSupply) {
            revert StablecoinMinter__ExceedsMaximumSupply();
        }

        // Update the user's stablecoin balances
        userStablecoinBalances[msg.sender] += mintableStablecoin;
    }

    function redeemCollateral(IERC20 collateral, uint256 stablecoinAmount) external {
        // Check if user has enough stablecoins
        if (userStablecoinBalances[msg.sender] < stablecoinAmount) {
            revert StablecoinMinter__InsufficientStablecoinBalance();
        }

        if (block.timestamp >= lockExpiration[msg.sender][collateral]) {
            revert StablecoinMinter__LockExpired_WithdrawDirectly();
        }

        // Check if user has enough collateral
        uint256 collateralAmount = stablecoinAmount / collateralToStablecoinRatio;
        if (userCollateralBalances[msg.sender][collateral] < collateralAmount) {
            revert StablecoinMinter__InsufficientCollateralBalance();
        }

        // Burn stablecoins and reduce collateral balance
        userStablecoinBalances[msg.sender] -= stablecoinAmount;
        userCollateralBalances[msg.sender][collateral] -= collateralAmount;
        SafeERC20.safeTransfer(collateral, msg.sender, collateralAmount);

        // Emit LockCountDown
        uint256 remainingTime = lockExpiration[msg.sender][collateral] - block.timestamp;
        emit LockCountdown(msg.sender, collateral, remainingTime, block.timestamp);
    }

    function withdrawCollateral(IERC20 collateral) external {
        if (block.timestamp < lockExpiration[msg.sender][collateral]) {
            revert StablecoinMinter__LockStillAlive();
        }

        uint256 amount = userCollateralBalances[msg.sender][collateral];
        if (amount <= 0) {
            revert StablecoinMinter__NoCollateralToWithdraw();
        }

        // Decrease the total collateral locked by the amount being withdrawn
        totalCollateralLocked -= amount;

        // Reset collateral balances and timestamps
        userCollateralBalances[msg.sender][collateral] = 0;
        lockExpiration[msg.sender][collateral] = 0;
        lockTimestamp[msg.sender][collateral] = 0;

        // Transfer the collateral back to user
        SafeERC20.safeTransfer(collateral, msg.sender, amount);
    }
}
