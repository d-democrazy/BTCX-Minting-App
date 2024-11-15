// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IERC20} from "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {CollateralHelper} from "./CollateralHelper.sol";

contract StablecoinMinting {
    using CollateralHelper for IERC20[];
    using CollateralHelper for mapping(address => mapping(IERC20 => uint256));

    // Defining variables
    string public constant name = "Bitcoin Extended";
    string public constant symbol = "BTCX";
    uint8 public constant decimals = 18;
    uint256 public constant maximumSupply = 2_100_000_000 * 10 ** decimals;

    uint256 public totalCollateralLocked;

    IERC20[] public allowedCollaterals; // Allowed collaterals (stBTC, solvBTC, aBTC)
    uint256 public constant collateralToStablecoinRatio = 100; // Collateral : stablecoin is 1 : 100

    mapping(address => mapping(IERC20 => uint256))
        public userCollateralBalances;
    mapping(address => uint256) public userStablecoinBalances;

    mapping(address => mapping(IERC20 => uint256)) public lockExpiration;
    mapping(address => mapping(IERC20 => uint256)) public lockTimestamp;

    event LockCountdown(uint256 remainingTime, string message);

    constructor(IERC20[] memory _allowedCollaterals) {
        require(
            _allowedCollaterals.length > 0,
            "At least one collateral required"
        );
        for (uint256 i = 0; i < _allowedCollaterals.length; i++) {
            allowedCollaterals.push(_allowedCollaterals[i]);
        }
    }

    function lockCollateral(
        IERC20 collateral,
        uint256 amount,
        uint256 duration
    ) external {
        require(amount > 0, "Amount must be greater than zero");

        // Use library to check if the collateral is allowed
        require(
            allowedCollaterals.isAllowedCollaterals(collateral),
            "Collateral not allowed"
        );

        // Validate duration: must be one of the allowed duration
        require(
            duration == 10 days ||
                duration == 30 days ||
                duration == 90 days ||
                duration == 180 days ||
                duration == 365 days ||
                duration == 1095 days,
            "Invalid lock durations"
        );

        // Update the user's collateral balances and the total collateral locked
        userCollateralBalances[msg.sender][collateral] += amount;
        totalCollateralLocked += amount;

        // Set lock expiration and timestamp
        lockExpiration[msg.sender][collateral] = block.timestamp + duration;
        lockTimestamp[msg.sender][collateral] = block.timestamp;

        // Transfer collateral from the user to the contract
        SafeERC20.safeTransferFrom(
            collateral,
            msg.sender,
            address(this),
            amount
        );
    }

    function mintStablecoin() external {
        // Ensure the total collateral locked accross all users meet the minimum treshold
        require(
            totalCollateralLocked >= 1e16,
            "Total collateral locked must be at least 0.01 units"
        );

        // Use library to calculate the user's collateral balance
        uint256 userTotalCollateral = userCollateralBalances
            .getUserTotalCollateral(allowedCollaterals, msg.sender);

        // Calculate user's mintable stablecoins based on their share of the total collateral
        uint256 mintableStablecoin = (userTotalCollateral *
            collateralToStablecoinRatio *
            totalCollateralLocked) / totalCollateralLocked;

        // Ensure minting doesn't exceed the maximum supply
        require(
            userStablecoinBalances[msg.sender] + mintableStablecoin <=
                maximumSupply,
            "Exceeds maximum supply"
        );

        // Update the user's stablecoin balances
        userStablecoinBalances[msg.sender] += mintableStablecoin;
    }

    function redeemCollateral(
        IERC20 collateral,
        uint256 stablecoinAmount
    ) external {
        require(
            userStablecoinBalances[msg.sender] >= stablecoinAmount,
            "Insufficient stablecoin balance"
        );

        // Ensure the lock is still active
        require(
            block.timestamp < lockExpiration[msg.sender][collateral],
            "Lock expired, withdraw directly!"
        );

        uint256 collateralAmount = stablecoinAmount /
            collateralToStablecoinRatio;
        require(
            userCollateralBalances[msg.sender][collateral] >= collateralAmount,
            "insufficient collateral"
        );

        // Burn stablecoins and reduce collateral balance
        userStablecoinBalances[msg.sender] -= stablecoinAmount;
        userCollateralBalances[msg.sender][collateral] -= collateralAmount;
        SafeERC20.safeTransfer(collateral, msg.sender, collateralAmount);

        // Show countdown
        uint256 remainingTime = lockExpiration[msg.sender][collateral] -
            block.timestamp;
        emit LockCountdown(remainingTime, "Time remaining for unlock");
    }

    function withdrawCollateral(IERC20 collateral) external {
        require(
            block.timestamp >= lockExpiration[msg.sender][collateral],
            "Lock duration not over"
        );

        uint256 amount = userCollateralBalances[msg.sender][collateral];
        require(amount > 0, "No collateral to withdraw");

        // Decrease the total collateral lock by the amount being withdrawn
        totalCollateralLocked -= amount;

        // Reset collateral balances and timestamps
        userCollateralBalances[msg.sender][collateral] = 0;
        lockExpiration[msg.sender][collateral] = 0;
        lockTimestamp[msg.sender][collateral] = 0;

        // Transfer the collateral back to user
        SafeERC20.safeTransfer(collateral, msg.sender, amount);
    }
}
