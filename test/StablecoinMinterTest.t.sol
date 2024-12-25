// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console2} from "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {StablecoinMinter} from "../src/StablecoinMinter.sol";
import {MockERC20} from "./Mocks/MockERC20.sol";

contract StablecoinMinterTest is Test {
    StablecoinMinter stablecoinMinter;
    MockERC20 mockCollateral1;
    MockERC20 mockCollateral2;
    MockERC20 disallowedCollateral;

    address user = address(0x123);

    function setUp() external {
        // Deploy mock allowed and disallowed collateral tokens for testing
        mockCollateral1 = new MockERC20("Collateral1", "MBTC1", 1_000_000 ether);
        mockCollateral2 = new MockERC20("Collateral2", "MBTC2", 500_000 ether);
        disallowedCollateral = new MockERC20("Disallowed collateral", "dMCK", 1_000_000 ether);

        // Create an array with one or multiple allowed collaterals
        IERC20[] memory allowed = new IERC20[](2);
        allowed[0] = IERC20(address(mockCollateral1));
        allowed[1] = IERC20(address(mockCollateral2));

        // Deploy the StablecoinMinter with these allowed collaterals
        stablecoinMinter = new StablecoinMinter(allowed);

        // Distribute collaterals to the user for testing collateral locking
        mockCollateral1.transfer(user, 1_000 ether);
        mockCollateral2.transfer(user, 1_000 ether);
        disallowedCollateral.transfer(user, 1_000 ether);

        // Approve the stablecoinMinter to pull tokens from user
        vm.startPrank(user);
        mockCollateral1.approve(address(stablecoinMinter), type(uint256).max);
        mockCollateral2.approve(address(stablecoinMinter), type(uint256).max);
        disallowedCollateral.approve(address(stablecoinMinter), type(uint256).max);
        vm.stopPrank();
    }

    function testConstructorRevertsWithEmptyCollaterals() external {
        // Prepare an empty array of IERC20
        IERC20[] memory emptyCollaterals = new IERC20[](0);

        // Expect revert with the specific custom error
        vm.expectRevert(StablecoinMinter.StablecoinMinter__InsufficientAllowedCollateral.selector);

        // Attempt deployment
        new StablecoinMinter(emptyCollaterals);
    }

    function testConstructorWithNonEmptyCollaterals() external view {
        /**
         * Check that allowedCollaterals are set correctly
         * Since allowedCollaterals is public array, consider exposing getter or adding a function that returns all allowedCollaterals if needed.
         */
        IERC20 firstCollateral = stablecoinMinter.allowedCollaterals(0);
        IERC20 secondCollateral = stablecoinMinter.allowedCollaterals(1);

        assertEq(address(firstCollateral), address(mockCollateral1), "first collateral address");
        assertEq(address(secondCollateral), address(mockCollateral2), "Second collateral address");

        // Check constants
        assertEq(stablecoinMinter.name(), "Bitcoin Extended");
        assertEq(stablecoinMinter.symbol(), "BTCX");
        assertEq(stablecoinMinter.decimals(), 1e18);
        assertEq(stablecoinMinter.maximumSupply(), 2_100_000_000 * 1e18);
    }

    function testLockCollateralRevertsIfAmountIsZero() external {
        vm.startPrank(user);
        IERC20[] memory allowedCollaterals = new IERC20[](2);
        allowedCollaterals[0] = IERC20(address(mockCollateral1));
        allowedCollaterals[1] = IERC20(address(mockCollateral2));

        vm.expectRevert(StablecoinMinter.StablecoinMinter__MoreThanZeroAmount.selector);
        stablecoinMinter.lockCollateral(allowedCollaterals[0], 0, 30 days);

        vm.expectRevert(StablecoinMinter.StablecoinMinter__MoreThanZeroAmount.selector);
        stablecoinMinter.lockCollateral(allowedCollaterals[1], 0, 30 days);
    }

    function testLockCollateralRevertsIfNotAllowedCollateral() external {
        vm.startPrank(user);
        vm.expectRevert(StablecoinMinter.StablecoinMinter__NotAllowedCollateral.selector);

        stablecoinMinter.lockCollateral(disallowedCollateral, 100 ether, 30 days);
        vm.stopPrank();
    }

    function testLockCollateralRevertsIfInvalidDuration() external {
        vm.startPrank(user);
        IERC20[] memory allowedCollaterals = new IERC20[](2);
        allowedCollaterals[0] = IERC20(address(mockCollateral1));
        allowedCollaterals[1] = IERC20(address(mockCollateral2));
        vm.expectRevert(StablecoinMinter.StablecoinMinter__InvalidLockDuration.selector);

        stablecoinMinter.lockCollateral(allowedCollaterals[0], 100 ether, 60 days); // not allowed
        vm.stopPrank();
    }

    function testLockCollateralSuccessfulLock() external {
        uint256 lockAmount = 100 ether;
        uint256 duration = 30 days;
        IERC20[] memory allowedCollaterals = new IERC20[](2);
        allowedCollaterals[0] = IERC20(address(mockCollateral1));
        allowedCollaterals[1] = IERC20(address(mockCollateral2));

        // Check initial balances and states
        uint256 initialUserBalance = 0;
        for (uint256 i = 0; i < allowedCollaterals.length; i++) {
            initialUserBalance += allowedCollaterals[i].balanceOf(user);
        }
        uint256 initialContractBalance = 0;
        for (uint256 i = 0; i < allowedCollaterals.length; i++) {
            initialContractBalance += allowedCollaterals[i].balanceOf(address(stablecoinMinter));
        }
        uint256 initialUserCollateral = stablecoinMinter.userCollateralBalances(user, allowedCollaterals[0]);
        uint256 initialTotalCollateral = stablecoinMinter.totalCollateralLocked();

        vm.startPrank(user);
        stablecoinMinter.lockCollateral(allowedCollaterals[0], lockAmount, duration);
        vm.stopPrank();

        // Check final balances and states
        uint256 finalUserBalance = 0;
        for (uint256 i = 0; i < allowedCollaterals.length; i++) {
            finalUserBalance += allowedCollaterals[i].balanceOf(user);
        }
        uint256 finalContractBalance = 0;
        for (uint256 i = 0; i < allowedCollaterals.length; i++) {
            finalContractBalance += allowedCollaterals[i].balanceOf(address(stablecoinMinter));
        }
        uint256 finalUserCollateral = stablecoinMinter.userCollateralBalances(user, allowedCollaterals[0]);
        uint256 finalTotalCollateral = stablecoinMinter.totalCollateralLocked();

        // User collateral balance should increase by lockAmount
        assertEq(finalUserCollateral, initialUserCollateral + lockAmount, "User collateral not updated correctly");

        // Total collateral locked should increase by lockAmount
        assertEq(finalTotalCollateral, initialTotalCollateral + lockAmount, "Total collateral not updated correctly");

        // Check token transfer
        assertEq(finalUserBalance, initialUserBalance - lockAmount, "User token balance not reduced correctly");
        assertEq(
            finalContractBalance, initialContractBalance + lockAmount, "Contract token balance not increased correctly"
        );

        // Check lock expiration and timestamp
        uint256 expiration = stablecoinMinter.lockExpiration(user, allowedCollaterals[0]);
        uint256 timestamp = stablecoinMinter.lockTimestamp(user, allowedCollaterals[0]);
        uint256 currentBlockTimeStamp = block.timestamp;

        assertEq(expiration, currentBlockTimeStamp + duration, "Lock expiration not set correctly");
        assertEq(timestamp, currentBlockTimeStamp, "Lock timestamp not set correctly");
    }

    function testMintStablecoinRevertsIfBelowMinimumCollateral() external {
        // Make totalCollateralLocked <0.01
        vm.startPrank(user);
        stablecoinMinter.lockCollateral(mockCollateral1, 0.005 ether, 30 days);
        vm.expectRevert(StablecoinMinter.StablecoinMinter__TotalCollateralLockedMustBeAtLeastMoreThanMinimum.selector);

        stablecoinMinter.mintStablecoin();
        vm.stopPrank();
    }

    function testLockCollateralRevertsIfExceedsMaximumCollateral() external {
        // totalCollateralLocked slot idex is 0
        bytes32 slotIndex = bytes32(uint256(0));
        // Convert 21,000,000 to bytes32
        uint256 maxCollateralRaw = 21_000_000 ether;
        bytes32 storeValue = bytes32(maxCollateralRaw);

        // Forcefully set totalCollateralLocked to 21,000,000 in the stablecoinMinter
        vm.store(address(stablecoinMinter), slotIndex, storeValue);
        console2.log("Forced totalCollateralLocked after store:", stablecoinMinter.totalCollateralLocked());

        // Double check that the totalCollateralLocked is set correctly
        uint256 forcedValue = stablecoinMinter.totalCollateralLocked();
        assertEq(forcedValue, maxCollateralRaw, "Failed to set totalCollateralLocked to 21M");

        // User tries to lock 0.1 additional collateral => totalCollateralLocked would become 21,000,000.1
        // Expect revert with StablecoinMinter__TotalCollateralLockedExceedsMaximum
        vm.startPrank(user);
        vm.expectRevert(StablecoinMinter.StablecoinMinter__TotalCollateralLockedExceedsMaximum.selector);
        stablecoinMinter.lockCollateral(mockCollateral1, 0.1 ether, 30 days);
        vm.stopPrank();
    }

    function testMintStablecoinRevertsIfExceedsMaximumSupply() external {
        // 1. Manually set totaolCollateralLocked to 21,000,000 ether via slot 0
        bytes32 slot0 = bytes32(uint256(0));
        uint256 maxCollateralRaw = 21_000_000 ether;
        bytes32 value0 = bytes32(maxCollateralRaw);
        vm.store(address(stablecoinMinter), slot0, value0);

        // 2. Manually set userCollateralBalances[user][mockCollateral1] to 21,000,000 ether
        bytes32 userSlot = keccak256(abi.encode(user, uint256(2))); // slot 2 is userCollateralBalances
        bytes32 collateralSlot = keccak256(abi.encode(mockCollateral1, userSlot));
        uint256 userCollateralAmount = 21_000_000 ether;
        bytes32 value2 = bytes32(uint256(userCollateralAmount));
        vm.store(address(stablecoinMinter), collateralSlot, value2);

        // 3. Verify that totalCollateralLocked is correctly set
        uint256 forcedTotalCollateral = stablecoinMinter.totalCollateralLocked();
        assertEq(forcedTotalCollateral, maxCollateralRaw, "Failed to set totalCollateralLocked");

        // 4. verify that userCollateralBalances[user][mockCollateral1] is correctly set
        uint256 userCollateral = stablecoinMinter.userCollateralBalances(user, mockCollateral1);
        assertEq(userCollateral, userCollateralAmount, "Failed to set userCollateralBalances");

        // 5. Mint once, should mint 21,000,000 * 100 = 2,100,000,000 stablecoins (maxSupply)
        vm.startPrank(user);
        stablecoinMinter.mintStablecoin();
        vm.stopPrank();

        // 6. Attempt to mint again, should fail with ExceedsMaximumSupply
        vm.startPrank(user);
        vm.expectRevert(StablecoinMinter.StablecoinMinter__ExceedsMaximumSupply.selector);
        stablecoinMinter.mintStablecoin();
        vm.stopPrank();
    }

    function testMintStablecoinSuccess() external {
        uint256 lockAmount = 5 * 1e17; // User locks 0.5 collateral units

        // The user must call lockCollateral, not the test contract
        vm.startPrank(user);
        stablecoinMinter.lockCollateral(mockCollateral1, lockAmount, 30 days);
        vm.stopPrank();

        // totalCollateralLocked is now 0.5 (>= 0.01 && <= 21,000,000)
        // So we pass the min and max checks

        // userStablecoinBalances before = 0
        uint256 userStablecoinsBefore = stablecoinMinter.userStablecoinBalances(user);

        vm.startPrank(user);
        stablecoinMinter.mintStablecoin();
        vm.stopPrank();

        uint256 userStablecoinsAfter = stablecoinMinter.userStablecoinBalances(user);

        // 1:100 => 0.5 collateral * 100 ratio = 50 stablecoins minted
        uint256 expectedMint = 5 * 1e17 * 100; // 50 stablecoins (assuming same decimals logic)
        require(userStablecoinsAfter == userStablecoinsBefore + expectedMint, "Incorrect mint amount");
    }
}
