// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console2} from "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {StablecoinMinter} from "../src/StablecoinMinter.sol";
import {MockERC20} from "./Mocks/MockERC20.sol";

contract StablecoinMinterTest is Test {
    MockERC20 mockCollateral1;
    MockERC20 mockCollateral2;

    function setUp() external {
        // Deploy mock collateral tokens for testing
        mockCollateral1 = new MockERC20("Collateral1", "MBTC1", 1_000_000 ether);
        mockCollateral2 = new MockERC20("Collateral2", "MBTC2", 500_000 ether);
    }

    function testConstructorRevertsWithEmptyCollaterals() external {
        // Prepare an empty array of IERC20
        IERC20[] memory emptyCollaterals = new IERC20[](0);

        // Expect revert with the specific custom error
        vm.expectRevert(StablecoinMinter.StablecoinMinter__InsufficientAllowedCollateral.selector);

        // Attempt deployment
        new StablecoinMinter(emptyCollaterals);
    }

    function testConstructorWithNonEmptyCollaterals() external {
        // Create an array with one or multiple allowed collaterals
        IERC20[] memory allowed = new IERC20[](2);
        allowed[0] = IERC20(address(mockCollateral1));
        allowed[1] = IERC20(address(mockCollateral2));

        // Deploy the StablecoinMinter with these allowed collaterals
        StablecoinMinter stablecoinMinter = new StablecoinMinter(allowed);

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
        assertEq(stablecoinMinter.decimals(), 18);
        assertEq(stablecoinMinter.maximumSupply(), 2_100_000_000 * 10 ** 18);
    }
}
