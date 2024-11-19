// SPDX-License-Identifier: MIT

/**
 * 1. Deploy collateral testnet addresses when we are on core testnet
 * 2. Deploy collateral mainnet addresses when we are on core mainnet
 */

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {IERC20} from "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract HelperConfig is Script {
    address[] public collateralAddresses;
    address[] public testnetCollateral;
    address[] public mainnetCollateral;

    struct NetworkConfig {
        address[] collateralAddresses; // Array of collateral token addresses
    }

    NetworkConfig internal activeNetworkConfig;

    constructor() {
        collateralAddresses.push(0x559852401e545f941F275B5674afAfcb1b51D147);
        collateralAddresses.push(0xF9173645D5A391d9Fb29Fc3438024499E3AC5eD0);
        collateralAddresses.push(0x2A41E6cBEcd491BcAc8EBEc766F696c6868dF5Bb);
        collateralAddresses.push(0x7C346C27Ef3A48B1AE0454D994A49005C720D6FA);
        collateralAddresses.push(0x0000000000000000000000000000000000000000);
        collateralAddresses.push(0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa);
        collateralAddresses.push(0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB);
        collateralAddresses.push(0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC);

        activeNetworkConfig = NetworkConfig(collateralAddresses);

        if (block.chainid == 1115) {
            activeNetworkConfig = getCoreTestnetConfig();
        } else if (block.chainid == 1116) {
            activeNetworkConfig = getCoreMainnetConfig();
        }
        revert("Unsupported Network");
    }

    function getCoreTestnetConfig() internal returns (NetworkConfig memory) {
        testnetCollateral[0] = 0x559852401e545f941F275B5674afAfcb1b51D147;
        testnetCollateral[1] = 0xF9173645D5A391d9Fb29Fc3438024499E3AC5eD0;
        testnetCollateral[2] = 0x2A41E6cBEcd491BcAc8EBEc766F696c6868dF5Bb;
        testnetCollateral[3] = 0x7C346C27Ef3A48B1AE0454D994A49005C720D6FA;

        return NetworkConfig({collateralAddresses: testnetCollateral});
    }

    function getCoreMainnetConfig() internal returns (NetworkConfig memory) {
        mainnetCollateral[0] = 0x0000000000000000000000000000000000000000;
        mainnetCollateral[1] = 0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa;
        mainnetCollateral[2] = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;
        mainnetCollateral[3] = 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC;

        return NetworkConfig({collateralAddresses: mainnetCollateral});
    }

    /**
     * @notice Returns allowed collaterals as IERC20 array.
     * Convert addresses into IERC20 instances dynamically for compatibility.
     * @return IERC20[] array of allowed collateral tokens.
     */

    function getAllowedCollaterals() external view returns (IERC20[] memory) {
        address[] memory addresses = activeNetworkConfig.collateralAddresses;
        IERC20[] memory allowedCollaterals = new IERC20[](addresses.length);

        for (uint256 i = 0; i < addresses.length; i++) {
            allowedCollaterals[i] = IERC20(addresses[i]);
        }
        return allowedCollaterals;
    }
}
