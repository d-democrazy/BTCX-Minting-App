// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {CollateralManager} from "src/CollateralManager.sol";

contract StablecoinMinter {
    /**
     * errors ******
     */
    //
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
    error StablecoinMinter__LockExpiredStillAlive();
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

    event LockCountdown(uint256 remainingTime, string message);

    constructor(IERC20[] memory _allowedCollaterals) {
        if (_allowedCollaterals.length == 0) {
            revert StablecoinMinter__InsufficientAllowedCollateral();
        }
        // require(
        //     _allowedCollaterals.length > 0,
        //     "At least one collateral required"
        // );
        for (uint256 i = 0; i < _allowedCollaterals.length; i++) {
            allowedCollaterals.push(_allowedCollaterals[i]);
        }
    }

    function lockCollateral(IERC20 collateral, uint256 amount, uint256 duration) external {
        if (amount <= 0) {
            revert StablecoinMinter__MoreThanZeroAmount();
        }
        // require(amount > 0, "Amount must be greater than zero");

        // Use library to check if the collateral is allowed
        if (!allowedCollaterals.isAllowedCollaterals(collateral)) {
            revert StablecoinMinter__NotAllowedCollateral();
        }
        // require(
        //     allowedCollaterals.isAllowedCollaterals(collateral),
        //     "Collateral not allowed"
        // );

        // Validate duration: must be one of the allowed duration
        if (
            duration != 10 days && duration != 30 days && duration != 90 days && duration != 180 days
                && duration != 365 days && duration != 1095 days
        ) {
            revert StablecoinMinter__InvalidLockDuration();
        }
        // require(
        //     duration == 10 days ||
        //         duration == 30 days ||
        //         duration == 90 days ||
        //         duration == 180 days ||
        //         duration == 365 days ||
        //         duration == 1095 days,
        //     "Invalid lock durations"
        // );

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

        // require(
        //     totalCollateralLocked >= MINIMUM_COLLATERAL,
        //     "Total collateral locked must be at least 0.01 units"
        // );
        if (totalCollateralLocked + amount > MAXIMUM_COLLATERAL) {
            revert StablecoinMinter__TotalCollateralLockedExceedsMaximum();
        }
        // require(
        //     totalCollateralLocked <= MAXIMUM_COLLATERAL,
        //     "Total collateral locked exceeds 21,000,000 units"
        // );

        // Use library to calculate the user's collateral balance
        uint256 userTotalCollateral = userCollateralBalances.getUserTotalCollateral(allowedCollaterals, msg.sender);

        // Calculate user's mintable stablecoins based on their share of the total collateral
        uint256 mintableStablecoin =
            (userTotalCollateral * collateralToStablecoinRatio * totalCollateralLocked) / totalCollateralLocked;

        // Ensure minting doesn't exceed the maximum supply
        if (userStablecoinBalances[msg.sender] + mintableStablecoin > maximumSupply) {
            revert StablecoinMinter__ExceedsMaximumSupply();
        }
        // require(
        //     userStablecoinBalances[msg.sender] + mintableStablecoin <=
        //         maximumSupply,
        //     "Exceeds maximum supply"
        // );

        // Update the user's stablecoin balances
        userStablecoinBalances[msg.sender] += mintableStablecoin;
    }

    function redeemCollateral(IERC20 collateral, uint256 stablecoinAmount) external {
        if (userStablecoinBalances[msg.sender] >= stablecoinAmount) {
            revert StablecoinMinter__InsufficientStablecoinBalance();
        }

        // require(
        //     userStablecoinBalances[msg.sender] >= stablecoinAmount,
        //     "Insufficient stablecoin balance"
        // );

        // Ensure the lock is still active
        if (block.timestamp < lockExpiration[msg.sender][collateral]) {
            revert StablecoinMinter__LockExpired_WithdrawDirectly();
        }

        // require(
        //     block.timestamp < lockExpiration[msg.sender][collateral],
        //     "Lock expired, withdraw directly!"
        // );

        uint256 collateralAmount = stablecoinAmount / collateralToStablecoinRatio;
        if (userCollateralBalances[msg.sender][collateral] >= collateralAmount) {
            revert StablecoinMinter__InsufficientCollateralBalance();
        }

        // require(
        //     userCollateralBalances[msg.sender][collateral] >= collateralAmount,
        //     "insufficient collateral"
        // );

        // Burn stablecoins and reduce collateral balance
        userStablecoinBalances[msg.sender] -= stablecoinAmount;
        userCollateralBalances[msg.sender][collateral] -= collateralAmount;
        SafeERC20.safeTransfer(collateral, msg.sender, collateralAmount);

        // Show countdown
        uint256 remainingTime = lockExpiration[msg.sender][collateral] - block.timestamp;
        emit LockCountdown(remainingTime, "Time remaining for unlock");
    }

    function withdrawCollateral(IERC20 collateral) external {
        if (block.timestamp >= lockExpiration[msg.sender][collateral]) {
            revert StablecoinMinter__LockExpiredStillAlive();
        }

        // require(
        //     block.timestamp >= lockExpiration[msg.sender][collateral],
        //     "Lock duration not over"
        // );

        uint256 amount = userCollateralBalances[msg.sender][collateral];
        if (amount <= 0) {
            revert StablecoinMinter__NoCollateralToWithdraw();
        }
        // require(amount > 0, "No collateral to wi thdraw");

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
