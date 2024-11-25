// SPDX-License-Identifier: MIT

/**
 * 1. Deploy collateral testnet addresses when we are on core testnet
 * 2. Deploy collateral mainnet addresses when we are on core mainnet
 * 3. Deploy collateral mocks addresses when we are on Sepolia
 */

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract HelperConfigTryout is Script {
    uint256 public constant CORE_TESTNET_ID = 1115;
    uint256 public constant CORE_MAINNET_ID = 1116;
    uint256 public constant SEPOLIA_ID = 11155111;

    address[] public _collateralAddresses = [
        0x559852401e545f941F275B5674afAfcb1b51D147,
        0xF9173645D5A391d9Fb29Fc3438024499E3AC5eD0,
        0x2A41E6cBEcd491BcAc8EBEc766F696c6868dF5Bb,
        0x7C346C27Ef3A48B1AE0454D994A49005C720D6FA,
        0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa,
        0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB,
        0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC,
        0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd
    ];

    struct NetworkConfig {
        address[] collateralAddresses; // Array of collateral token addresses
    }

    NetworkConfig activeNetworkConfig;

    constructor() {
        if (block.chainid == CORE_TESTNET_ID) {
            activeNetworkConfig = getCoreTestnetConfig();
        } else if (block.chainid == CORE_MAINNET_ID) {
            activeNetworkConfig = getCoreMainnetConfig();
        } else if (block.chainid == SEPOLIA_ID) {
            activeNetworkConfig = getSepoliaConfig();
        } else {
            // Fallback for unsupported networks (logs, no revert)
            console.log("Unsupported Network:", block.chainid);
            return;
        }
    }

    function getCoreTestnetConfig() public returns (NetworkConfig memory) {
        activeNetworkConfig.collateralAddresses.push(_collateralAddresses[0]);
        activeNetworkConfig.collateralAddresses.push(_collateralAddresses[1]);
        activeNetworkConfig.collateralAddresses.push(_collateralAddresses[2]);
        activeNetworkConfig.collateralAddresses.push(_collateralAddresses[3]);

        return activeNetworkConfig;
    }

    function getCoreMainnetConfig() public returns (NetworkConfig memory) {
        activeNetworkConfig.collateralAddresses.push(_collateralAddresses[4]);
        activeNetworkConfig.collateralAddresses.push(_collateralAddresses[5]);
        activeNetworkConfig.collateralAddresses.push(_collateralAddresses[6]);
        activeNetworkConfig.collateralAddresses.push(_collateralAddresses[7]);

        return activeNetworkConfig;
    }

    function getSepoliaConfig() public returns (NetworkConfig memory) {
        activeNetworkConfig.collateralAddresses.push(_collateralAddresses[4]);
        activeNetworkConfig.collateralAddresses.push(_collateralAddresses[5]);
        activeNetworkConfig.collateralAddresses.push(_collateralAddresses[6]);
        activeNetworkConfig.collateralAddresses.push(_collateralAddresses[7]);

        return activeNetworkConfig;
    }

    /**
     * @notice Returns allowed collaterals as IERC20 array.
     * Convert addresses into IERC20 instances dynamically for compatibility.
     * @return IERC20[] array of allowed collateral tokens.
     */

    function getAllowedCollaterals() public view returns (IERC20[] memory) {
        address[] memory addresses = activeNetworkConfig.collateralAddresses;
        IERC20[] memory allowedCollaterals = new IERC20[](addresses.length);

        for (uint256 i = 0; i < addresses.length; i++) {
            allowedCollaterals[i] = IERC20(addresses[i]);
        }
        return allowedCollaterals;
    }
}
