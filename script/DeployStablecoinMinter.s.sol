// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {StablecoinMinter} from "../src/StablecoinMinter.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {IERC20} from "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployStablecoinMinter is Script {
    function run() external {
        vm.startBroadcast();

        HelperConfig helperConfig = new HelperConfig();
        IERC20[] memory allowedCollaterals = helperConfig
            .getAllowedCollaterals();

        // Deploy the StablecoinMinter contract
        StablecoinMinter stablecoinMinter = new StablecoinMinter(
            allowedCollaterals
        );

        // Log the deployed contract address
        console.log("StablecoinMinter deployed at:", address(stablecoinMinter));

        vm.stopBroadcast();
    }
}
