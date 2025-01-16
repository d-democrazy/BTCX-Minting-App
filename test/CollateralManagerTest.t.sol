// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CollateralManager} from "../src/CollateralManager.sol";
import {MockERC20} from "./Mocks/MockERC20.sol";

contract CollateralManagerTest is Test {
    using CollateralManager for IERC20[];
    using CollateralManager for mapping(address => mapping(IERC20 => uint256));

    IERC20[] internal allowedCollaterals;
    mapping(address => mapping(IERC20 => uint256)) internal userCollateralBalances;

    address user1 = address(0x111);
    address user2 = address(0x222);

    MockERC20 mockCollateral1;
    MockERC20 mockCollateral2;
    MockERC20 mockCollateral3;

    function setUp() public {
        // Deploy mock tokens
        mockCollateral1 = new MockERC20("MockCollateral1", "MC1", 0);
        mockCollateral2 = new MockERC20("MockCollateral2", "MC2", 0);
        mockCollateral3 = new MockERC20("MockCollateral3", "MC3", 0);

        // Add some to allowedCollaterals
        allowedCollaterals.push(mockCollateral1);
        allowedCollaterals.push(mockCollateral2);
    }

    // ==========================================
    // A. isAllowedCollaterals() Tests
    // ==========================================

    function testIsAllowedCollaterals_ReturnsTrueIfCollateralIsAllowed() external view {
        bool isAllowed = allowedCollaterals.isAllowedCollaterals(mockCollateral1);
        assertEq(isAllowed, true, "mockCollateral1 should be allowed");
    }

    function testIsAllowedCollaterals_ReturnsFalseIfCollateralNotAllowed() external view {
        bool isAllowed = allowedCollaterals.isAllowedCollaterals(mockCollateral3);
        assertEq(isAllowed, false, "mockCollateral3 should NOT be allowed");
    }

    function testIsAllowedCollaterals_ReturnsFalseIfEmptyAllowedCollaterals() external {
        // 1. Clear the storage array
        delete allowedCollaterals; // Now allowedCollaterals.length == 0 in storage

        bool isAllowed = allowedCollaterals.isAllowedCollaterals(mockCollateral1);
        assertEq(isAllowed, false, "Should return false for empty collaterals array");
    }

    // ==========================================
    // B. getUserTotalCollateral() Tests
    // ==========================================

    function testGetUserTotalCollateral_ReturnsZeroIfNoCollateral() external view {
        // user1 has nothing set
        uint256 total = userCollateralBalances.getUserTotalCollateral(allowedCollaterals, user1);
        assertEq(total, 0, "Should be 0 if user has no collateral");
    }

    function testGetUserTotalCollateral_ReturnsSingleCollateralAmount() external {
        // user1 has 100 in mockCollateral1
        userCollateralBalances[user1][mockCollateral1] = 100 ether;

        uint256 total = userCollateralBalances.getUserTotalCollateral(allowedCollaterals, user1);
        assertEq(total, 100 ether, "Should only sum the single collateral");
    }

    function testGetUserTotalCollateral_MultipleCollaterals() external {
        userCollateralBalances[user1][mockCollateral1] = 50 ether;
        userCollateralBalances[user1][mockCollateral2] = 150 ether;

        uint256 total = userCollateralBalances.getUserTotalCollateral(allowedCollaterals, user1);
        assertEq(total, 200 ether, "Should sum multiple collaterals for user1");
    }

    function testGetUserTotalCollateral_MultipleUsers() external view {
        // user1
        userCollateralBalances[user1][mockCollateral1] = 50 ether;
        userCollateralBalances[user1][mockCollateral2] = 150 ether;

        // user2
        userCollateralBalances[user2][mockCollateral1] = 10 ether;
        userCollateralBalances[user2][mockCollateral2] = 90 ether;

        uint256 totalUser1 = userCollateralBalances.getUserTotalCollateral(allowedCollaterals, user1);
        uint256 totalUser2 = userCollateralBalances.getUserTotalCollateral(allowedCollaterals, user2);

        assertEq(totalUser1, 200 ether, "User1 total should be 50 + 150 = 200");
        assertEq(totalUser2, 100 ether, "User2 total should be 10 + 90 = 100");
    }
}
