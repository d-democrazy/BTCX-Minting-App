// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {StablecoinMinter} from "../src/StablecoinMinter.sol";
import {HelperConfigTryout} from "./HelperConfigTryout.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployStablecoinMinter is Script {
    function run() external {
        HelperConfigTryout helperConfigTryout = new HelperConfigTryout();
        IERC20[] memory allowedCollaterals = helperConfigTryout.getAllowedCollaterals();

        vm.startBroadcast();
        // Deploy the StablecoinMinter contract
        StablecoinMinter stablecoinMinter = new StablecoinMinter(allowedCollaterals);

        // Log the deployed contract address
        console.log("StablecoinMinter deployed at:", address(stablecoinMinter));
        console.log("Detected chain ID:", block.chainid);

        vm.stopBroadcast();
    }
}
